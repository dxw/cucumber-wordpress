# encoding: utf-8

require 'singleton'
require 'fileutils'
require 'uri'
require 'mysql'
Mysql::Result.send(:include, Enumerable)

class WordPress
  require 'cucumber-wordpress/path_to'
  include Singleton

  def self.method_missing(method, *args, &block)
    self.instance.send(method, *args, &block)
  end

  attr_accessor :config, :passwords, :original_contents, :tables
  attr_accessor :ABSPATH, :WEBHOST, :DB_NAME, :DB_USER, :DB_PASSWORD, :DB_HOST, :DB_CHARSET, :DB_COLLATE, :TABLE_PREFIX

  def configure(data)
    @config = data
    @ABSPATH = data['ABSPATH'].to_s
    @WEBHOST = data['WEBHOST'].to_s
    @DB_NAME = data['DB_NAME'].to_s
    @DB_USER = data['DB_USER'].to_s
    @DB_PASSWORD = data['DB_PASSWORD'].to_s
    @DB_HOST = data['DB_HOST'].to_s
    @DB_CHARSET = data['DB_CHARSET'].to_s
    @DB_COLLATE = data['DB_COLLATE'].to_s
    @TABLE_PREFIX = data['TABLE_PREFIX'].to_s
    @tables = %w[comments
                 links
                 options
                 postmeta
                 posts
                 term_relationships
                 term_taxonomy
                 terms
                 usermeta
                 users].map{|t|@TABLE_PREFIX+t}
  end

  def mysql
    @mysql ||= Mysql::new(@DB_HOST, @DB_USER, @DB_PASSWORD)
    @mysql
  end

  def create_db
    mysql.query("create database #{@DB_NAME} character set = #{@DB_CHARSET}#{@DB_COLLATE.empty? ? '' : " collate = #{@DB_COLLATE}"}")
    mysql.query("use #{@DB_NAME}")
  end

  def drop_db
    mysql.query("drop database if exists #{@DB_NAME}")
  end

  def write_config
    # Copy production DB elsewhere
    @has_config = File.exist? File.join(@ABSPATH,'wp-config.php')
    FileUtils.cp File.join(@ABSPATH,'wp-config.php'), File.join(@ABSPATH,'.wp-config.php') if @has_config

    extra_config = ''
    yield extra_config if block_given?

    # Write our own
    open(File.join(@ABSPATH,'wp-config.php'),'w+') do |f|
      f.write <<HERE
<?php
define('WP_DEBUG', true);
define('DB_NAME', '#{@DB_NAME}');
define('DB_USER', '#{@DB_USER}');
define('DB_PASSWORD', '#{@DB_PASSWORD}');
define('DB_HOST', '#{@DB_HOST}');
define('DB_CHARSET', '#{@DB_CHARSET}');
define('DB_COLLATE', '#{@DB_COLLATE}');
$table_prefix  = '#{@TABLE_PREFIX}';
if ( !defined('ABSPATH') ) define('ABSPATH', dirname(__FILE__) . '/');
#{extra_config}
require_once(ABSPATH . 'wp-settings.php');
HERE
    end
  end

  def reset_config
    FileUtils.rm File.join(@ABSPATH,'wp-config.php')
    FileUtils.mv File.join(@ABSPATH,'.wp-config.php'), File.join(@ABSPATH,'wp-config.php') if @has_config
  end

  def reset_db
    @original_contents.nil? ? nil : @original_contents.each_pair do |table,contents|
      mysql.query("delete from #{table}")
      contents.each do |row|
        values = row.map{|v|"#{v.nil? ? 'null' : "'"+Mysql.escape_string(v)+"'"}"}.join(', ')
        mysql.query("insert into #{table} values (#{values})")
      end
    end
  end

  def get_post_id(title)
    WordPress.mysql.query(%Q'SELECT ID FROM #{WordPress.TABLE_PREFIX}posts WHERE post_title="#{title}"').fetch_row.first.to_i
  end

  def php code
    `php -r '$_SERVER["SERVER_SOFTWARE"]=""; $_SERVER["REQUEST_URI"]="/"; include "#{WordPress.ABSPATH}/wp-load.php"; #{code};' 2>/dev/null`
  end

  def version
    return @version if @version
    @version = php 'global $wp_version; echo $wp_version;'
    @version.match(/^(\d+)\.(\d+)(:?\.(\d+))?$/)
    @major = $1.to_i
    @minor = $2.to_i
    @patch = $3.to_i
    @version
  end

  def major
    version
    @major
  end
  def minor
    version
    @minor
  end
  def patch
    version
    @patch
  end
end
