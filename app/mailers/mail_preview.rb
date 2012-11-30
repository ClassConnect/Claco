class MailPreview < MailView
  # Pull data from existing fixtures
  def newsletter
    UserMailer.newsletter(Teacher.first)
  end

  def new_sub
    UserMailer.new_sub(Teacher.first.id, Teacher.last.id)
  end
end