# SPDX-FileCopyrightText: 2023 CERN
# SPDX-License-Identifier: MIT

# frozen_string_literal: true

class MsGraphPollSettingsValidator
  def initialize(opts = {})
    @opts = opts
  end

  def valid_value?(val)
    return true if val == "f"

    begin
      auth_url =
        "https://login.microsoftonline.com/#{SiteSetting.msgraph_polling_tenant_id}/oauth2/v2.0/token"
      oauth_provider =
        OAuth2::Client.new(
          SiteSetting.msgraph_polling_client_id,
          nil,
          token_url: auth_url
        )
      token =
        OAuth2::AccessToken.new(
          oauth_provider,
          nil,
          refresh_token: SiteSetting.msgraph_polling_oauth2_refresh_token
        ).refresh!

      msgraph_api =
        MsGraphAPI.new(
          "https://graph.microsoft.com/v1.0",
          SiteSetting.msgraph_polling_mailbox,
          token.token
        )

      msgraph_api.get_messages_id

      return true
    rescue StandardError => e
      Rails.logger.warn("MSGraphAPI validation failed: #{e}")
      return false
    end
  end

  def error_message
    I18n.t("errors.msgraph_poll_settings")
  end
end
