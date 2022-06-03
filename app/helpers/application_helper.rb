module ApplicationHelper
  def flash_messages
    %i[success warning danger].map { |type| alert_box(type) }.join.html_safe
  end

  def alert_box(type)
    "<div class='text-center'>
      <span class='text-#{type}'>#{flash[type]}</span>
    </div>"
  end
end
