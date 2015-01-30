# encoding: utf-8

module JobsHelper

  def filter_params(filters)
    params.slice(:page, :status, :app_id).merge(filters)
  end
end
