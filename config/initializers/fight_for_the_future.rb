module FightForTheFuture
    def FightForTheFuture.help
      puts '# Methods'
      
      [
        'find_or_create_action_page_by_tag',
        'refresh_email_statistics',
      ]
    end

    def FightForTheFuture.find_or_create_action_page_by_tag(tag)
        unless page = ActionPage.find_by_name(tag)
          campaign = Campaign.find_by_name('CMS')
          
          page = ActionPage.create(
            name: tag,
            movement_id: 1,
            type: 'ActionPage',
            action_sequence_id: campaign.action_sequences.first.id
          )

          petition = PetitionModule.create!(
            :title => "Sign, please",
            :content => 'We the undersigned...',
            :petition_statement => "This is the petition statement",
            :signatures_goal => 1,
            :thermometer_threshold => 0,
            :language => Language.find_by_iso_code(:en)
          )
          ContentModuleLink.create!(:page => page, :content_module => petition, :position => 3, :layout_container => :main_content)
        end

        page
    end

    def FightForTheFuture.refresh_email_statistics
      now = Time.zone.now
      UniqueActivityByEmail.delay(:run_at=>now).update!
    end
end
