class NullifyListingTenantMemberReferences < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :listings, column: :created_by_tenant_member_id
    remove_foreign_key :listings, column: :updated_by_tenant_member_id

    add_foreign_key :listings,
                    :tenant_members,
                    column: :created_by_tenant_member_id,
                    on_delete: :nullify
    add_foreign_key :listings,
                    :tenant_members,
                    column: :updated_by_tenant_member_id,
                    on_delete: :nullify
  end
end
