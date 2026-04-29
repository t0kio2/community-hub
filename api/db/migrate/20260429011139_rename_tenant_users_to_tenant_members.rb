class RenameTenantUsersToTenantMembers < ActiveRecord::Migration[8.1]
  def change
    rename_table :tenant_members, :tenant_members
  end
end
