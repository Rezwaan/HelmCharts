class Zendesk::UserService
  def find_or_create(account_id:)
    account = Accounts::AccountService.new.fetch(id: account_id)
    return unless account
    zendesk_user = $zendesk.users.search(query: "email:#{account[:email].downcase}").first
    return zendesk_user if zendesk_user.present?
    $zendesk.user.create!(name: (account[:name].blank? ? account[:username] : account[:name]), email: account[:email].downcase, verified: true)
  end
end
