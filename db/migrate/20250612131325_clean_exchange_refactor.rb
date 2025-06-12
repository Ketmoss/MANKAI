class CleanExchangeRefactor < ActiveRecord::Migration[7.1]
   def up
    # 1. Nettoyer complètement l'ancienne structure
    remove_foreign_key :chats, :exchanges if foreign_key_exists?(:chats, :exchanges)

    # Supprimer tous les index existants de la table exchanges
    if table_exists?(:exchanges)
      connection.indexes(:exchanges).each do |index|
        remove_index :exchanges, name: index.name
      end
    end

    # Supprimer la table exchanges complètement
    drop_table :exchanges if table_exists?(:exchanges)

    # 2. Créer la nouvelle table exchanges avec des noms d'index uniques
    create_table :exchanges do |t|
      # Les deux utilisateurs participants
      t.references :initiator, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }

      # Ce que chaque utilisateur VEUT (chez l'autre)
      t.references :wanted_manga, null: false, foreign_key: { to_table: :owned_mangas }
      t.references :offered_manga, null: true, foreign_key: { to_table: :owned_mangas }

      # Statut de l'échange (integer pour enum)
      t.integer :status, default: 0, null: false

      # Message initial de l'initiateur
      t.text :initial_message

      # Informations du rendez-vous
      t.datetime :meeting_date
      t.string :meeting_location
      t.text :meeting_notes

      # Timestamps de suivi
      t.datetime :accepted_at
      t.datetime :completed_at
      t.datetime :cancelled_at

      t.timestamps
    end

    # 3. Ajouter les index avec des noms explicites pour éviter les conflits
    add_index :exchanges, [:initiator_id, :status], name: 'idx_exchanges_initiator_status'
    add_index :exchanges, [:recipient_id, :status], name: 'idx_exchanges_recipient_status'
    add_index :exchanges, :wanted_manga_id, name: 'idx_exchanges_wanted_manga'
    add_index :exchanges, :offered_manga_id, name: 'idx_exchanges_offered_manga'
    add_index :exchanges, [:initiator_id, :recipient_id, :wanted_manga_id],
              unique: true, name: 'idx_unique_exchange_request'

    # 4. Rétablir la contrainte de clé étrangère pour chats
    add_foreign_key :chats, :exchanges

    # 5. Ajouter des colonnes aux utilisateurs pour la confidentialité
    add_column :users, :collection_visibility, :integer, default: 0
    add_column :users, :allow_exchange_requests, :boolean, default: true

    # 6. Améliorer owned_mangas pour les échanges
    rename_column :owned_mangas, :available, :available_for_exchange
    add_column :owned_mangas, :condition_notes, :text

    # 7. Modifier la table messages pour ajouter l'auteur
    add_reference :messages, :user, null: false, foreign_key: true

    # Associer les messages existants au créateur du chat
    execute <<-SQL
      UPDATE messages
      SET user_id = (
        SELECT chats.user_id
        FROM chats
        WHERE chats.id = messages.chat_id
      )
      WHERE messages.user_id IS NULL
    SQL

    # 8. Supprimer la colonne role des messages
    remove_column :messages, :role if column_exists?(:messages, :role)

    # 9. Modifier la table chats
    remove_column :chats, :model_id if column_exists?(:chats, :model_id)
    change_column_null :chats, :user_id, true

    say "✅ Système d'échange recréé avec succès !"
    say "✅ #{User.count} utilisateurs avec paramètres de confidentialité"
    say "✅ #{OwnedManga.count} mangas avec disponibilité d'échange"
    say "✅ #{Message.count} messages avec auteurs"
    say "✅ #{Chat.count} chats prêts pour les échanges"
  end

  def down
    # Nettoyer avant de restaurer
    remove_foreign_key :chats, :exchanges if foreign_key_exists?(:chats, :exchanges)

    # Supprimer tous les index de la nouvelle table
    if table_exists?(:exchanges)
      connection.indexes(:exchanges).each do |index|
        remove_index :exchanges, name: index.name
      end
    end

    drop_table :exchanges if table_exists?(:exchanges)

    # Recréer l'ancienne table exchanges
    create_table :exchanges do |t|
      t.string :status
      t.references :user, null: false, foreign_key: true
      t.references :owned_manga, null: false, foreign_key: true
      t.timestamps
    end

    # Rétablir la contrainte de clé étrangère pour chats
    add_foreign_key :chats, :exchanges

    # Restaurer les colonnes supprimées/modifiées
    remove_column :users, :collection_visibility if column_exists?(:users, :collection_visibility)
    remove_column :users, :allow_exchange_requests if column_exists?(:users, :allow_exchange_requests)

    rename_column :owned_mangas, :available_for_exchange, :available
    remove_column :owned_mangas, :condition_notes if column_exists?(:owned_mangas, :condition_notes)

    remove_reference :messages, :user if column_exists?(:messages, :user_id)
    add_column :messages, :role, :string

    add_column :chats, :model_id, :string
    change_column_null :chats, :user_id, false
  end
end
