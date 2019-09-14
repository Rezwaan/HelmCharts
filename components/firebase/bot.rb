require "google/cloud/firestore"

class Firebase::Bot
  def initialize(config: nil)
    @config = config
  end

  def generate_auth_token(uid, claims)
    now_seconds = Time.now.to_i
    private_key = config_app_config&.dig(:private_key)
    escaped_private_key = private_key&.gsub('\n', "\n")
    private_key = OpenSSL::PKey::RSA.new escaped_private_key
    client_email = config_app_config&.dig(:client_email)
    payload = {
      iss: client_email,
      sub: client_email,
      aud: "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit",
      iat: now_seconds,
      exp: now_seconds + (60 * 60), # Maximum expiration time is one hour , this should be changed for depending on the user
      uid: uid.to_s,
      claims: claims,
    }
    JWT.encode(payload, private_key, "RS256")
  end

  def app_config
    {
      apiKey: config_app_config[:apiKey],
      authDomain: config_app_config[:authDomain],
      projectId: config_app_config[:projectId],
    }
  end

  def fetch_document(path:)
    doc_ref = firestore.doc path
    snapshot = doc_ref.get
    return nil unless snapshot.exists?

    snapshot.data
  end

  def create_document(path:, data:)
    doc_ref = firestore.doc path
    doc_ref.set data
  end

  def filter(collection:, criteria:, fields:)
    collection_ref = firestore.col collection
    # TODO support chained query
    query = collection_ref.where criteria.first[:field], criteria.first[:operator], criteria.first[:value]
    query.select(*fields)
    query.get
  end

  def config_app_config
    @config&.dig(:app_config) || {}
  end

  def firestore
    @firestore ||= Google::Cloud::Firestore.new keyfile: Google::Auth::GCECredentials.new
  end
end
