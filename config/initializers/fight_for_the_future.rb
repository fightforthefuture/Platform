module FightForTheFuture

    def FightForTheFuture.find_or_create_action_page_by_tag(tag)
        unless page = ActionPage.find_by_name(tag)
          # Find campaign.
          campaign = Campaign.find_by_name('CMS')
          
          # Create Action Page.
          page = ActionPage.create(
            name: tag,
            movement_id: 1,
            type: 'ActionPage',
            action_sequence_id: campaign.action_sequences.first.id
          )

          # Create Petition Module.
          petition = PetitionModule.create!(
            :title => "Sign, please",
            :content => 'We the undersigned...',
            :petition_statement => "This is the petition statement",
            :signatures_goal => 1,
            :thermometer_threshold => 0,
            :language => Language.find_by_iso_code(:en)
          )

          # Link Action Page & Petition Module.
          ContentModuleLink.create!(:page => page, :content_module => petition, :position => 3, :layout_container => :main_content)
        end

        page
    end

    def FightForTheFuture.refresh_email_statistics
      now = Time.zone.now
      UniqueActivityByEmail.delay(:run_at=>now).update!
    end

    def FightForTheFuture.delete_user_by_email(email)
      # Find user.
      user = User.find_by_email(email)

      # Delete user.
      ActiveRecord::Base.connection.execute "DELETE FROM `users` WHERE (email = '#{email}') LIMIT 1"

      # Delete events.
      UserActivityEvent.where(user_id: user.id).each do
        |e|
        e.delete
      end
    end

    def FightForTheFuture.find_or_create_user(email, first_name = '', source = '')
      # Find user.
      user = User.find_by_email(email)

      # Create user, if necessary.
      if !user
        user = User.where(email: email, first_name: first_name, created_at: Time.now, updated_at: Time.now, created_by: "Imported", movement_id: 1, language_id: 1, source: source).build
        user.save
      end

      user
    end

    def FightForTheFuture.create_user_activity_event(user, page)
      # Determine IDs.
      user_id = (user.class == User) ? user.id : user
      page_id = (page.class == ActionPage) ? page.id : page

      # Create event.
      UserActivityEvent.create(user_id: user_id, activity: "action_taken", content_module_type: "Imported", user_response_type: "Imported", created_at: Time.now, updated_at: Time.now, campaign_id: 41, page_id: page_id, movement_id: 1)
    end

end
