When /^I start rest\-assured with (.*)$/ do |options|
  @app_config = fake_start_rest_assured(options)
end

Then /^it should run on port (\d+)$/ do |port|
  @app_config[:port].should == port
end

Then /^the log file should be (.*)$/ do |logfile|
  @app_config[:logfile].should == logfile
  `rm #{logfile}`
end

Then /^database adapter should be sqlite and db file should be (.*)$/ do |dbfile|
  @app_config[:database].should == dbfile
  @app_config[:adapter].should == 'sqlite'
  `rm #{dbfile}`
end

Then /^database adapter should be mysql, db name should be "([^"]*)", db user should be "([^"]*)", user password should be "([^"]*)" and db host should be "([^"]*)"$/ do |dbname, user, password, host|
  @app_config[:adapter].should == 'mysql'
  @app_config[:database].should == dbname
  @app_config[:username].should == user
  @app_config[:password].should == password
  @app_config[:host].should == host
end