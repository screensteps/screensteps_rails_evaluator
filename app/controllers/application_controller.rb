class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def json_render(record, jsonapi_args: {}, **kw_args)
    # record is not necessarily an ActiveRecord instance
    if record.try(:errors).present?
      render jsonapi_errors: record.errors, status: :unprocessable_content
    else
      render jsonapi: record, **jsonapi_params_with(jsonapi_args), **kw_args
    end
  end

  def json_render_error(exception, status: :unprocessable_content)
    render jsonapi_errors: {
             title: exception.class.name.demodulize.titleize,
             detail: exception.message
           },
           status: status
  end

  def jsonapi_params_with(jsonapi_args)
    append = transform_append_param || []
    {
      expose: { user_context: user_context, append: append }.merge(jsonapi_args[:expose] || {}),
      include: [params[:include], jsonapi_args[:include]].compact.join(',')
    }.merge(jsonapi_args.except(:expose, :include, :append))
  end

  def paginate(records, per_page, paginator = :keyset, already_ordered: false, **options)
    meta = {}
    meta[:meta] = { total_entries: records.count } if records.is_a?(ActiveRecord::Relation) && include_total_entries?

    options.reverse_merge!(limit: per_page, querify: ->(q) { q.merge!('page[limit]' => per_page) })

    # Adding ordering on id at the end enforces a unique ordering.
    # Most of the time it's a good idea to add this, but it doesn't always play nicely with custom
    # SQL queries.
    records = records.order(:id) unless already_ordered

    pagy, records = pagy(paginator, records, jsonapi: true, absolute: true, page_key: 'offset', **options)
    meta[:links] = pagy.urls_hash

    [records, meta]
  end

  private

  def jsonapi_page_params
    @jsonapi_page_params ||= params.permit(page: {})[:page] || {}
  end

  # Whether to include total_entries in the meta for a nextlink request.
  # Only returns true when the page[total_entries] query param is a truthy value and we're returning
  # the first page of results (no offset param provided).
  def include_total_entries?
    jsonapi_page_params[:total_entries].to_bool && jsonapi_page_params[:offset].nil?
  end
end
