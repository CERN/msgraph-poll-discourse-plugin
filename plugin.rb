# SPDX-FileCopyrightText: 2023 CERN
# SPDX-License-Identifier: MIT

# frozen_string_literal: true

# name: msgraph-polling
# about: A plugin to enable polling mails using Microsoft Graph API
# version: 1.0
# authors: CERN
# url: https://github.com/cern/msgraph-poll-discourse-plugin

require_relative "lib/msgraph-poller/api.rb"

require "oauth2"

enabled_site_setting :msgraph_polling_enabled

after_initialize do
  class ::MsGraphEmailPoller < Email::Poller
    def initialize
      auth_url =
        "#{SiteSetting.msgraph_polling_login_endpoint}/#{SiteSetting.msgraph_polling_tenant_id}/oauth2/v2.0/token"
      oauth_provider =
        OAuth2::Client.new(
          SiteSetting.msgraph_polling_client_id,
          nil,
          token_url: auth_url
        )
      @token =
        OAuth2::AccessToken.new(
          oauth_provider,
          nil,
          refresh_token: SiteSetting.msgraph_polling_oauth2_refresh_token
        )
      
      begin
        @token = @token.refresh! if self.enabled?
        SiteSetting.msgraph_polling_oauth2_refresh_token = @token.refresh_token
      rescue StandardError => e
        Rails.logger.error(
          "Error while initializing MSGraph plugin: #{e}"
        )
      end
    end

    def enabled?
      SiteSetting.msgraph_polling_enabled?
    end

    def refresh_token_if_needed
      @token = @token.refresh! if @token.expired?
      SiteSetting.msgraph_polling_oauth2_refresh_token = @token.refresh_token
    end

    def poll_mailbox(process_cb)
      begin
        self.refresh_token_if_needed()

        msgraph_api =
          MsGraphAPI.new(
            SiteSetting.msgraph_polling_graph_endpoint,
            SiteSetting.msgraph_polling_mailbox,
            @token.token
          )

        # To avoid managing paging we get all the emails until there are none remaining
        while (messages = msgraph_api.get_messages_id).length > 0
          messages.each do |message|
            mime = msgraph_api.get_message_mime(message)
            process_cb.call(mime)
            msgraph_api.delete_message(message)
          end
        end
      rescue StandardError => e
        Rails.logger.error(
          "Error while polling emails with MsGraph plugin: #{e}"
        )
      end
    end
  end

  register_email_poller(::MsGraphEmailPoller.new)
end

load File.expand_path(
       "../lib/validators/msgraph_poll_settings_validator.rb",
       __FILE__
     )
