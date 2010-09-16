module Rack
  module OAuth2
    module Server
      class Token < Abstract::Handler

        def call(env)
          request = Request.new(env)
          request.profile.new(@realm, &@authenticator).call(env).finish
        rescue Error => e
          e.finish
        end

        class Request < Abstract::Request
          attr_accessor :grant_type, :client_secret

          def initialize(env)
            super
            @grant_type    = params['grant_type']
            @client_secret = params['client_secret']
          end

          def required_params
            super + [:grant_type]
          end

          def profile(allow_no_profile = false)
            case params['grant_type']
            when 'authorization_code'
              AuthorizationCode
            when 'password'
              Password
            when 'assertion'
              Assertion
            when 'refresh_token'
              RefreshToken
            else
              raise BadRequest.new(:unsupported_grant_type, "'#{params['grant_type']}' isn't supported.")
            end
          end

        end

        class Response < Abstract::Response
          attr_accessor :access_token, :expires_in, :refresh_token, :scope

          def required_params
            super + [:access_token]
          end

          def finish
            params = {
              :access_token => access_token,
              :expires_in => expires_in,
              :scope => Array(scope).join(' ')
            }.delete_if do |key, value|
              value.blank?
            end
            write params.to_json
            header['Content-Type'] = "application/json"
            super
          end
        end

      end
    end
  end
end

require 'rack/oauth2/server/token/authorization_code'
require 'rack/oauth2/server/token/password'
require 'rack/oauth2/server/token/assertion'
require 'rack/oauth2/server/token/refresh_token'