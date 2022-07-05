class CreateCritics < ActiveRecord::Migration[7.0]
  def change
    create_table :critics do |t|
      t.string :title
      t.string :body_text
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
