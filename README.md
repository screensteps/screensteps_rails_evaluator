# ScreenSteps Rails Evaluator

A Rails application used as a candidate skills assessment project. It provides a sandbox environment for evaluating practical Ruby on Rails development abilities.

## Prerequisites

- **Ruby** 3.4+
- **Rails** 8.1
- **SQLite** 3.31+

## Models

- **Account** — A tenant/organization.
- **User** — A member of an account.
- **Space** — A documentation site belonging to an account.
- **Manual** — A collection of documentation content within a space.

## Running Tests

```bash
bundle exec rspec
```

## Questions
### Account model
[ ] Create a has_many relation that only returns the users with a role of "admin". Call it "admin_users".

### Space model
[ ] #clone_space could be improved. Tell me what you would change.

### User model
[ ] Specs get failures when ran. See how many you can fix. The specs should not be changed, just the code in the User model.

### User::Finder
[ ] Find out where the search_text filter used on line 4 is defined and describe how it works.

### ActiveRecord queries
Seed the database with the seeds.rb file, then from the Rails console:
[ ] Find all Manuals that have a title of "Work in Progress".
[ ] Find all Spaces that contain a manual with the title "Work in Progress".
[ ] Find the first User with a first_name of "Acme" and a last_name not equal to "Admin".

### Routing
[ ] There's no definition in routes.rb for the controller at api/users_controller. Create an entry for the actions here.
