require 'singleton'
require 'mysql'
Mysql::Result.send(:include, Enumerable)

class WordPress
  include Singleton

  def self.method_missing(method, *args)
    self.instance.send(method, *args)
  end

  attr_accessor :passwords, :mysql, :original_contents
  attr_accessor :WEBHOST, :DB_NAME, :DB_USER, :DB_PASSWORD, :DB_HOST, :DB_CHARSET, :DB_COLLATE, :TABLE_PREFIX

  def configure(data)
    @WEBHOST = data['WEBHOST'].to_s
    @DB_NAME = data['DB_NAME'].to_s
    @DB_USER = data['DB_USER'].to_s
    @DB_PASSWORD = data['DB_PASSWORD'].to_s
    @DB_HOST = data['DB_HOST'].to_s
    @DB_CHARSET = data['DB_CHARSET'].to_s
    @DB_COLLATE = data['DB_COLLATE'].to_s
    @TABLE_PREFIX = data['TABLE_PREFIX'].to_s
  end

  def create_db
    @mysql = Mysql::new(@DB_HOST, @DB_USER, @DB_PASSWORD)
    @mysql.query("create database if not exists #{@DB_NAME} character set = #{@DB_CHARSET}#{@DB_COLLATE.present? ? " collate = #{@DB_COLLATE}" : ''}")
    @mysql.query("use #{@DB_NAME}")
  end

  def drop_db
    @mysql.query("drop database if exists #{@DB_NAME}")
  end

  def write_config
    # Copy production DB elsewhere
    @has_config = File.exist? 'wp-config.php'
    FileUtils.cp 'wp-config.php', '.wp-config.php' if @has_config

    # Write our own
    open('wp-config.php','w+') do |f|
      f.write <<HERE
<?php
define('DB_NAME', '#{@DB_NAME}');
define('DB_USER', '#{@DB_USER}');
define('DB_PASSWORD', '#{@DB_PASSWORD}');
define('DB_HOST', '#{@DB_HOST}');
define('DB_CHARSET', '#{@DB_CHARSET}');
define('DB_COLLATE', '#{@DB_COLLATE}');
$table_prefix  = '#{@TABLE_PREFIX}';
if ( !defined('ABSPATH') ) define('ABSPATH', dirname(__FILE__) . '/');
require_once(ABSPATH . 'wp-settings.php');
HERE
    end
  end

  def reset_config
    FileUtils.rm 'wp-config.php'
    FileUtils.mv '.wp-config.php', 'wp-config.php' if @has_config
  end

  def reset_db
    @original_contents.nil? ? nil : @original_contents.each_pair do |table,contents|
      @mysql.query("delete from #{@TABLE_PREFIX}#{table}")
      contents.each do |row|
        values = row.map{|v|"#{v.nil? ? 'null' : "'"+Mysql.escape_string(v)+"'"}"}.join(', ')
        @mysql.query("insert into #{@TABLE_PREFIX}#{table} values (#{values})")
      end
    end
  end

  def path_to(page_name)
    partial = case page_name
    when /^homepage$/
      '/'
    when /^login page$/
      '/wp-login.php'
    when /^admin dashboard$/
      '/wp-admin/'
    when /^upload new consultation$/
      '/wp-admin/consultation-new.php'
    when /^media library$/
      "/wp-admin/upload.php"
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n"
    end
    URI::join("http://#{@WEBHOST}/", partial)
  end
end
