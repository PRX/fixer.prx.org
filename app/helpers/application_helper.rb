# encoding: utf-8

require 'uri'

module ApplicationHelper

  def paginate objects, options = {}
    options.reverse_merge!( theme: 'twitter-bootstrap' )

    super( objects, options )
  end

  def body_tag_id
    ['Fixer', controller_name.capitalize, action_name.capitalize].join("::")
  end

  def link_to_prx(name, path='')
    link_to(name, "http://www.prx.org/#{path}").html_safe
  end

  def hash_to_table(hsh)
    return hsh unless (hsh && hsh.is_a?(Hash))
    content_tag(:table, :class=>'table table-condensed') do
      hsh.keys.collect do |k|
        content_tag(:tr) do
          content_tag(:th, k) + content_tag(:td, hash_to_table(hsh[k]))
        end
      end.join(' ').html_safe
    end
  end

  def sanitize_uri(uri)
    return unless uri
    URI.parse(uri).tap do |u|
      u.user = 'REDACTED' if u.user
      u.password = 'REDACTED' if u.password
    end.to_s
  rescue
    ''
  end

end
