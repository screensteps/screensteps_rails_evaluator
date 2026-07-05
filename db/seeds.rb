# Idempotent seeds for development/testing.
# Run with: bin/rails db:seed

# ---------------------------------------------------------------------------
# Accounts
# ---------------------------------------------------------------------------

acme = Account.find_or_create_by!(domain: "acme") do |a|
  a.company = "Acme Corp"
  a.status  = "active"
  a.activated_at = Time.current
end

beta = Account.find_or_create_by!(domain: "beta") do |a|
  a.company = "Beta Inc"
  a.status  = "trial"
  a.activated_at = Time.current
end

# ---------------------------------------------------------------------------
# Users  (login required; email required for admin/editor)
# ---------------------------------------------------------------------------

[acme, beta].each do |account|
  slug = account.domain  # "acme" or "beta"

  admin = User.find_or_create_by!(login: "#{slug}_admin", account: account) do |u|
    u.first_name = slug.capitalize
    u.last_name  = "Admin"
    u.email      = "#{slug}_admin@example.com"
    u.role       = "admin"
    u.activated_at = Time.current
  end

  User.find_or_create_by!(login: "#{slug}_editor", account: account) do |u|
    u.first_name = slug.capitalize
    u.last_name  = "Editor"
    u.email      = "#{slug}_editor@example.com"
    u.role       = "editor"
    u.activated_at = Time.current
  end

  User.find_or_create_by!(login: "#{slug}_reader", account: account) do |u|
    u.first_name = slug.capitalize
    u.last_name  = "Reader"
    u.role       = "reader"
    u.activated_at = Time.current
  end

  # Set owner to admin if not already set
  account.update!(owner: admin) if account.owner_id.nil?
end

# ---------------------------------------------------------------------------
# Spaces
# ---------------------------------------------------------------------------

acme_admin  = User.find_by!(login: "acme_admin",  account: acme)
beta_admin  = User.find_by!(login: "beta_admin",  account: beta)

spaces = {
  acme => [
    { title: "Acme Private Docs",  permalink: "acme-private",  "protected": true  },
    { title: "Acme Public Docs",   permalink: "acme-public",   "protected": false },
  ],
  beta => [
    { title: "Beta Private Docs",  permalink: "beta-private",  "protected": true  },
    { title: "Beta Public Docs",   permalink: "beta-public",   "protected": false },
  ],
}

spaces.each do |account, space_defs|
  space_defs.each do |attrs|
    space = Space.find_or_create_by!(account: account, permalink: attrs[:permalink]) do |s|
      s.title     = attrs[:title]
      s.protected = attrs[:protected]
      s.language  = "en"
    end

    creator = account == acme ? acme_admin : beta_admin

    # Internal "Uncategorized" manual (one per space)
    Manual.find_or_create_by!(space: space, title: "Uncategorized", internal: true)

    # Published manuals
    [
      { title: "Getting Started",   permalink: "getting-started",   draft: false },
      { title: "User Guide",        permalink: "user-guide",        draft: false },
      { title: "FAQ",               permalink: "faq",               draft: false },
    ].each do |m|
      Manual.find_or_create_by!(space: space, title: m[:title]) do |manual|
        manual.permalink  = m[:permalink]
        manual.draft      = m[:draft]
        manual.internal   = false
        manual.restricted = false
        manual.creator    = creator
        manual.icon       = "book"
      end
    end

    # Only create this in the private spaces
    if space.protected?
      # Draft manual
      Manual.find_or_create_by!(space: space, title: "Work in Progress") do |manual|
        manual.draft      = true
        manual.internal   = false
        manual.restricted = false
        manual.creator    = creator
        manual.icon       = "wrench"
      end
    end
  end
end

Space.find_or_create_by!(account: acme, permalink: 'gamma') do |s|
  s.title     = "Gamma Site"
  s.protected = true
  s.language  = "fr"
end

puts "Seeded #{Account.count} accounts, #{User.count} users, #{Space.count} spaces, #{Manual.count} manuals."
