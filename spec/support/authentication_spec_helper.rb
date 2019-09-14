module AuthenticationSpecHelper
  private

  def get_auth(account, path, params: nil, headers: nil)
    get path, params: params, headers: auth_header(account).merge(headers.to_h)
  end

  def head_auth(account, path, params: nil, headers: nil)
    head path, params: params, headers: auth_header(account).merge(headers.to_h)
  end

  def post_auth(account, path, params: nil, headers: nil)
    post path, params: params, headers: auth_header(account).merge(headers.to_h)
  end

  def put_auth(account, path, params: nil, headers: nil)
    put path, params: params, headers: auth_header(account).merge(headers.to_h)
  end

  def delete_auth(account, path, params: nil, headers: nil)
    delete path, params: params, headers: auth_header(account).merge(headers.to_h)
  end

  def auth_header(account)
    token = JWT.encode(
      {account_id: account.id, exp: (Time.now + 10.minutes).to_i},
      account.encrypted_password
    )
    {
      "Authorization": "Bearer #{token}",
    }
  end
end
