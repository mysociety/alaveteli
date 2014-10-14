# Allow the PublicBodyCategory model to be addressed using the same syntax
# as the old PublicBodyCategories class without needing to rename everything,
# make sure we're not going to break any themes
class PublicBodyCategories

    def self.method_missing(method, *args, &block)
        warn 'Use of PublicBodyCategories is deprecated and will be removed in release 0.21. Please use PublicBodyCategory instead.'
        PublicBodyCategory.send(method, *args, &block)
    end

end
