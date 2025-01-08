# Depending on spec run ordering an authority may or may not meet the criteria
# to have the tag auto-applied, and as such breaks the expectations (e.g.
# sometimes the tag string will be "foo", sometimes "foo not_many_requests").
# Use this in an `around` block to disable the tagging for specs that match a
# defined set of tags:
#
#   around do |example|
#     disable_not_many_requests_auto_tagging { example.run }
#   end
#
def disable_not_many_requests_auto_tagging
  orig = PublicBody.not_many_public_requests_size
  PublicBody.not_many_public_requests_size = 0
  yield
  PublicBody.not_many_public_requests_size = orig
end
