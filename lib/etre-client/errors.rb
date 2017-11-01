module Etre
  class Client
    class EntityIdSet < StandardError; end
    class EntityNotProvided < StandardError; end
    class EntityTypeMismatch < StandardError; end
    class IdNotProvided < StandardError; end
    class LabelNotSet < StandardError; end
    class PatchIdSet < StandardError; end
    class PatchNotProvided < StandardError; end
    class QueryNotProvided < StandardError; end
    class RequestFailed < StandardError; end
    class UnexpectedResponseCode < StandardError; end
  end
end
