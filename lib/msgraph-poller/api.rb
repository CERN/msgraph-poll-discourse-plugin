# SPDX-FileCopyrightText: 2023 CERN
# SPDX-License-Identifier: MIT


# frozen_string_literal: true

require 'oauth2'
require 'httparty'
require 'json'

class MsGraphAPI
  class RequestError < StandardError
  end

  class UnexpectedResponseCodeError < StandardError
  end

  def initialize(base_url, email, access_token)
    @base_url = base_url
    @access_token = access_token
    @email = email
  end

  def make_request(path, method, expected_response_code)
    headers = {
      Authorization: "Bearer #{@access_token}"
    }

    res = HTTParty.send(method, "#{@base_url}/#{path}", headers: headers)
      
    throw UnexpectedResponseCodeError.new(res.code) if res.code != expected_response_code

    res.body
  end

  def make_request_json(url, method, expected_response_code)
    JSON.parse(self.make_request(url, method, expected_response_code))
  end

  def get_messages_id()
    self.make_request_json("users/#{@email}/messages/?$select=id", :get, 200)['value'].map { |message| message['id'] }
  end

  def get_message_mime(message_id)
    self.make_request("users/#{@email}/messages/#{message_id}/$value", :get, 200)
  end

  def delete_message(message_id)
    self.make_request("users/#{@email}/messages/#{message_id}", :delete, 204)
  end
end