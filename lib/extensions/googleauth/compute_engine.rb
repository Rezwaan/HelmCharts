# This is a monkey patch for googleauth library till this PR is merged
# https://github.com/googleapis/google-auth-library-ruby/pull/223
module Google
  module Auth
    class GCECredentials < Signet::OAuth2::Client
      def self.on_gce?(options = {})
        c = options[:connection] || Faraday.default_connection
        resp = c.get COMPUTE_CHECK_URI { |req|
          req.options.timeout = 0.1
          req.headers["Metadata-Flavor"] = "Google"
        }
        return false unless resp.status == 200
        resp.headers["Metadata-Flavor"] == "Google"
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed
        false
      end
    end
  end
end
