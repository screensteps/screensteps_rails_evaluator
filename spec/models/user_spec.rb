describe User do
  let(:account) { default_account }
  let(:admin) { create(:admin_user) }
  let(:editor) { create(:editor_user, email: 'editor@editor.com') }
  let(:reader) { create(:reader_user) }
  let(:root_user) { create(:root) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  describe 'basic operations' do
    it 'converts blank names to nil' do
      user = build(:user, first_name: '', last_name: '  ')
      user.save!
      expect(user.first_name).to be_nil
      expect(user.last_name).to be_nil
    end
  end

  describe 'first_name and last_name' do
    it "doesn't accept invalid characters" do
      user = build(:user, first_name: '<b>Jim</b>', last_name: "<img src=x onerror=alert('Smith');>")
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include('angle brackets not allowed')
      expect(user.errors[:last_name]).to include('angle brackets not allowed')
    end
  end

  describe "the users can't change from locked roles" do
    let(:user) { create(:user, login: 'bob', role: 'api access') }

    it 'raises an exception' do
      expect do
        user.update!(role: 'admin')
      end.to raise_error(User::RoleLockedError, 'API Users cannot have their role changed (login: bob)')
    end

    it 'allows update to the login and password' do
      expect { user.update!(login: 'new_login') }.not_to raise_error
    end
  end

  describe 'new users' do
    let(:user) { build(:user, role: 'admin') }

    describe '#email' do
      it 'allows valid emails' do
        user.email = 'bob+smith@gmail.com'
        expect(user).to be_valid
        user.email = "bob'smith@gmail.com"
        expect(user).to be_valid
      end

      it 'user with email_required as false' do
        user.update(role: 'reader')

        user.email = 'bob smith'
        expect(user).not_to be_valid
        expect(user.errors[:email]).to eq(['is invalid'])

        # check for multiple emails
        user.email = 'camillaac3@gmail.com; kmarcelinmd@verizon.net'
        expect(user).not_to be_valid
        expect(user.errors[:email]).to eq(['is invalid'])

        # check for blank emails
        user.email = ''
        expect(user).to be_valid
      end

      it 'validates uniqueness with correct message for existing user' do
        user.update!(email: 'unique@screensteps.dev')
        new_user = build(:user, email: 'unique@screensteps.dev')

        expect(new_user).not_to be_valid
        expect(new_user.errors[:email]).to include('is already assigned to another user')

        caps_user = build(:user, email: 'UNIQUE@screensteps.dev')

        expect(caps_user).not_to be_valid
        expect(caps_user.errors[:email]).to include('is already assigned to another user')
      end

      it 'validates uniqueness with correct message for existing pending invite' do
        user.update(email: 'unique@screensteps.dev', invite_pending: true)
        new_user = build(:user, email: 'unique@screensteps.dev')

        expect(new_user).not_to be_valid
        expect(new_user.errors[:email]).to include('is already assigned to another user with a pending invite')

        caps_user = build(:user, email: 'UNIQUE@screensteps.dev')

        expect(caps_user).not_to be_valid
        expect(caps_user.errors[:email]).to include('is already assigned to another user with a pending invite')
      end

      it "doesn't look at pending invites for the email for other accounts when calculating error message" do
        # user from other account
        create(:user, email: 'unique@screensteps.dev', account: create(:account, with_owner: false),
                      invite_pending: true)
        create(:user, email: 'unique@screensteps.dev')

        new_user = build(:user, email: 'unique@screensteps.dev')

        expect(new_user).not_to be_valid
        expect(new_user.errors[:email]).to include('is already assigned to another user')
      end
    end

    describe '#login' do
      it 'does not allow spaces' do
        user.login = 'this is a login'

        expect(user).not_to be_valid
        expect(user.errors[:login]).to include('is invalid')
      end

      it 'scopes uniqueness to an account' do
        create(:user, login: 'bob')
        new_user = build(:user, login: 'bob', account: account)

        expect(new_user).not_to be_valid
        expect(new_user.errors[:login]).to include('is already assigned to another user')

        user.account = create(:account)
        expect { user.save! }.not_to raise_error
      end

      it 'scopes uniqueness to an account for user with an existing pending invite' do
        user.update(login: 'bob', invite_pending: true)
        new_user = build(:user, login: 'bob', account: account)

        expect(new_user).not_to be_valid
        expect(new_user.errors[:login]).to include('is already assigned to another user with a pending invite')
      end

      it 'does not allow short logins' do
        user.login = '1'
        expect(user).not_to be_valid
      end

      it 'allows emails as logins' do
        user.login = 'bob+me@screensteps.dev'
        expect(user).to be_valid
      end
    end

    describe '#timezone' do
      it "can't be set to an invalid value" do
        user.timezone = 'not a timezone'
        expect(user).not_to be_valid
      end

      it 'can be set to a valid value or blank' do
        user.timezone = 'Central Time (US & Canada)'
        expect(user).to be_valid

        user.timezone = ''
        expect(user).to be_valid

        user.timezone = nil
        expect(user).to be_valid
      end
    end
  end

  describe 'agent users' do
    let(:user) { create(:user, account: nil, role: 'backend_agent') }

    it 'creates an agent' do
      expect(user).to be_valid
      expect(user.backend_agent?).to be true
    end
  end

  describe '.find_for_account' do
    let(:backend_agent) { create(:user, account: nil, role: 'backend_agent') }

    it 'finds a user belonging to the account' do
      expect(User.find_for_account(account, id: user.id)).to eq(user)
    end

    it 'finds an agent user when account is provided' do
      expect(User.find_for_account(account, id: backend_agent.id)).to eq(backend_agent)
    end

    it 'finds an agent user when account is nil' do
      expect(User.find_for_account(nil, id: backend_agent.id)).to eq(backend_agent)
    end

    it 'returns nil when user does not exist' do
      expect(User.find_for_account(account, id: -1)).to be_nil
    end

    it 'does not find a user from a different account' do
      other_account = create(:account)
      other_user = create(:user, account: other_account)
      expect(User.find_for_account(account, id: other_user.id)).to be_nil
    end
  end

  describe 'roles' do
    it "doesn't allow an invalid role" do
      user = build(:user, role: 'voodoo-man')
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include 'is an invalid role'
    end

    it "assigns users set to the role of 'author' to 'editor'" do
      user = build(:user, role: 'author')
      expect(user.role).to eq('editor')
    end

    it "assigns users set to the role of 'learner' to 'reader'" do
      user = build(:user, role: 'learner')
      expect(user.role).to eq('reader')
    end

    it 'automatically downcases the role parameter' do
      user = build(:user, role: 'AdMiN')
      expect(user.role).to eq('admin')
      expect(user).to be_valid
    end

    it 'allows the root or backend_agent roles to be set when an account is empty' do
      user = build(:user, account: nil)
      %w[root backend_agent].each do |role|
        user.role = role
        expect(user).to be_valid
      end
    end

    it "doesn't allow the root or backend_agent roles to be set when an account is present" do
      user = build(:user, account: account)
      %w[root backend_agent].each do |role|
        user.role = role
        expect(user).not_to be_valid
      end
    end
  end

  describe '#deactivated' do
    it "doesn't allow when the user is the account owner" do
      user.account.owner = user

      expect(user.update(deactivated: true)).to be(false)
      expect(user.errors[:deactivated]).to eq(['cannot be set for account owners'])
    end
  end

  describe '#discard' do
    it "doesn't allow when the user is the account owner" do
      user.account.owner = user

      expect(user.discard).to be false
      expect(user.update(discarded_at: Time.current)).to be false
      expect(user.errors[:base]).to eq(['Account owners cannot be discarded'])

      user.account.owner = nil
      user.discarded_at = nil

      expect(user.discard).to be true
    end
  end
end
