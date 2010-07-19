Capistrano::Configuration.instance(:must_exist).load do
  
  task :release_tag do
    # get the release path
    depend :local,:command,"svn"
    
    puts "  * incrementing the PMOG Application Version"
    puts "  * current Version: #{AppVersion.instance.version}"
    AppVersion.instance.incremental
    puts "  * new version: #{AppVersion.instance.version}"
    
    # After incrementing the version above, assign the new value to a variable that we can use to create the tag etc;
    new_tag = AppVersion.instance.version

    # Build a variable for the new tag url
    tag_repo = "#{base_repository}/tags/#{new_tag}"
    
    puts "  * committing the updated version info file"
    commit_version = "svn ci lib/app_version.yml -m 'Commiting the version file for #{new_tag}'"
    puts "  * locally executing \"#{commit_version}\""
    system commit_version
    
    # Set the tag repo in the version file
    #AppVersion.instance.set_repository(tag_repo)
    
    puts "  *  creating a tag for version #{new_tag}"
    cmd = "svn copy #{base_repository}/trunk #{tag_repo} -m 'Tagging release version #{new_tag} of the PMOG Web Application'"
    puts  "  * locally executing \"#{cmd}\""
    system cmd

    set :repository, "#{tag_repo}"
    puts "repository: #{repository}"
  end    

  namespace :deploy do
    desc "Increment the version and commit the new version yaml to the svn repo"
    task :increment_version, :roles => :app, :except => {:no_release => true} do
      transaction do
        release_tag
        update_code
        web.disable
        symlink
        migrate
      end

      restart
      web.enable
    end

  end
  
end