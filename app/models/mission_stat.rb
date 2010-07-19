# MissionStat is a model for collecting statistics on Missions, for example
# - number of people dismiss, take or queue a stumbled mission
class MissionStat < ActiveRecord::Base
  has_one :user
  has_one :mission

  # Records a queued, dismissed or taken mission
  # - records the type of action taken
  # - records who performed the action
  # - records which mission was actioned
  # - defaults to a context of +stumble+
  def self.record(current_user, mission, params, context = 'stumble')
    MissionStat.create( 
                        :user_id => current_user.id,
                        :mission_id => mission.id,
                        :action => params['action'],
                        :context => context
                      )
  end

  def before_create
    self.id = create_uuid
  end
end
