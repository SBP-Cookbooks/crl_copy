#
# Cookbook Name:: crl_copy
# Library:: matchers
#
# Copyright (C) 2016 Schuberg Philis
#
# Created by: Stephen Hoekstra <shoekstra@schubergphilis.com>
#

if defined?(ChefSpec)
  def create_crl_copy(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:crl_copy, :create, resource_name)
  end

  def delete_crl_copy(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:crl_copy, :delete, resource_name)
  end
end
