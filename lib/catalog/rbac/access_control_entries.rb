module Catalog
  module RBAC
    class AccessControlEntries
      def initialize(group_uuids)
        @group_uuids = group_uuids
      end

      def ace_ids(permission, klass)
        AccessControlEntry.joins(:permissions).where(
          :permissions            => {
            :name => permission
          },
          :access_control_entries => {
            :group_uuid   => @group_uuids,
            :aceable_type => klass.to_s
          }
        ).collect { |ace| ace.aceable_id.to_s }
      end
    end
  end
end
