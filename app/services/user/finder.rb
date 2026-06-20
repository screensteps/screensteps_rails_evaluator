class User
  class Finder < ApplicationFinder
    def where(filter = {})
      account.users.search_text(filter[:name])
             .order(last_name: sort_direction(filter), first_name: sort_direction(filter))
             .distinct
    end

    private

    def sort_direction(filter)
      if ActiveRecord::QueryMethods::VALID_DIRECTIONS.include?(filter[:sort_direction])
        return filter[:sort_direction].to_sym
      end

      :asc
    end
  end
end
