# SPDX-FileCopyrightText: 2023 CERN
# SPDX-License-Identifier: MIT

# frozen_string_literal: true

require "oauth2"
require "faraday"
require "json"

class MsGraphAPI
  class UnexpectedResponseCodeError < StandardError
  end

  def initialize(base_url, email, access_token)
    @base_url = base_url
    @access_token = access_token
    @email = email
  end

  def make_request(path, method, expected_response_code)
    conn =
      Faraday.new(
        url: @base_url,
        headers: {
          "Authorization" => "Bearer #{@access_token}"
        }
      )
    res = conn.send(method, path)

    if res.status != expected_response_code
      throw UnexpectedResponseCodeError.new(res.status)
    end

    res.body
  end

  def make_request_json(url, method, expected_response_code)
    JSON.parse(self.make_request(url, method, expected_response_code))
  end

  def get_messages_id()
    self.make_request_json("users/#{@email}/messages/?$select=id", :get, 200)[
      "value"
    ].map { |message| message["id"] }
  end

  def get_message_mime(message_id)
    self.make_request(
      "users/#{@email}/messages/#{message_id}/$value",
      :get,
      200
    )
  end

  def delete_message(message_id)
    self.make_request("users/#{@email}/messages/#{message_id}", :delete, 204)
  end
end
