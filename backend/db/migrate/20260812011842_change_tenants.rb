class ChangeTenants < ActiveRecord::Migration[8.1]
  def change
    remove_column :tenants, :address, :string
    add_reference :tenants,
                  :primary_tenant_location,
                  foreign_key: { to_table: :tenant_locations }
  end
end
