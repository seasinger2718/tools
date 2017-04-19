import sys
import boto3
import botocore

class EC2_info:
  
  def parse_instance_id_or_name(self, instance_id_or_name):
    instance_id = None
    name = None
    if instance_id_or_name.startswith("i-"):
      instance_id = instance_id_or_name
    else:
      name = instance_id_or_name
    
    vals = {}
    vals['InstanceID'] = instance_id
    vals['Name'] = name
    
    return vals
    
  def get_matching_instance_ids(self, instance_id_or_name):
      response = self.parse_instance_id_or_name(instance_id_or_name)
      instance_id = response['InstanceID']
      name = response['Name']
      kwargs = {}
      if instance_id:
        kwargs['InstanceIds'] = [instance_id]
      else:
        name_filter = {}
        name_filter['Name'] = 'tag-value'
        name_filter['Values'] = ['*' + name + '*']
        kwargs['Filters'] = [ name_filter ]
        
      response = ec2_client.describe_instances(**kwargs)
      matching_instance_ids = []
      
      for reservation in response['Reservations']:
        for instance in reservation['Instances']:
          #print repr(instance) #DEBUG
          matching_instance_ids.append(instance['InstanceId'])
      
      return matching_instance_ids

  def get_dependent_information_for_ec2_instances(self,instance_ids = []):
    dependents_info = []
    for instance_id in instance_ids:
      dependents_info.append(self.get_dependent_information_for_ec2_instance(instance_id))
    return dependents_info
    
  def get_tag_value_from_tags(self, tags, tag_name):
    matching_tags = [tag for tag in tags if tag['Key'] == tag_name ]
    if len(matching_tags) > 0:
      return matching_tags[0]['Value']
    else:
      return None
    
  def get_security_group_info(self, security_group_id = None):
    kwargs = {}
    if security_group_id:
      kwargs['GroupIds'] = [security_group_id]

    response = ec2_client.describe_security_groups(**kwargs) 
    security_groups = response['SecurityGroups']
    if len(security_groups) > 0:
      security_group = security_groups[0]
      security_group_info = {}
      security_group_info['SecurityGroupId'] = security_group['GroupId']
      security_group_info['SecurityGroupName'] = security_group['GroupName']
      if 'Tags' in security_group :
        tags = security_group['Tags']
        security_group_info['SecurityTagProduct'] = self.get_tag_value_from_tags(tags,'product')
        security_group_info['SecurityTagService'] = self.get_tag_value_from_tags(tags,'service')
      else:
        security_group_info['SecurityTagProduct'] = None
        security_group_info['SecurityTagService'] = None
        
      return security_group_info
    else:
      return None

  def get_network_interface_info(self, network_interface_id = None):
    kwargs = {}
    if network_interface_id:
      kwargs['NetworkInterfaceIds'] = [network_interface_id]
    
    response = ec2_client.describe_network_interfaces(**kwargs)   
    network_interfaces = response['NetworkInterfaces']
    if len(network_interfaces) > 0:
      network_interface = network_interfaces[0]
      network_interface_info = {}
      network_interface_info['NetworkInterfaceId'] = network_interface['NetworkInterfaceId']
      network_interface_info['NetworkInterfaceDescription'] = network_interface['Description']
      if 'TagSet' in network_interface:
        tags = network_interface['TagSet']
        network_interface_info['NetworkInterfaceTagProduct'] = self.get_tag_value_from_tags(tags,'product')
        network_interface_info['NetworkInterfaceTagService'] = self.get_tag_value_from_tags(tags,'service')
      else:  
        network_interface_info['NetworkInterfaceTagProduct'] = None
        network_interface_info['NetworkInterfaceTagService'] = None
      
      return network_interface_info
      
    else:

      return None


    

  def get_volume_info(self, volume_id = None):
    kwargs = {}
    if volume_id:
      kwargs['VolumeIds'] = [volume_id]

    response = ec2_client.describe_volumes(**kwargs)   
    volumes = response['Volumes']
    if len(volumes) > 0:
      volume = volumes[0]
      volume_info = {}
      volume_info['VolumeId'] = volume['VolumeId']
      if 'Tags' in volume:
        tags = volume['Tags']
        volume_info['VolumeTagProduct'] = self.get_tag_value_from_tags(tags,'product')
        volume_info['VolumeTagService'] = self.get_tag_value_from_tags(tags,'service')
      else:
        volume_info['VolumeTagProduct'] = None
        volume_info['VolumeTagService'] = None

      return volume_info
      
    else:

      return None


    
  def get_dependent_information_for_ec2_instance(self,instance_id = None):
    dependent_info = {}
    
    kwargs = {}
    if instance_id:
      kwargs['InstanceIds'] = [instance_id]

    response = ec2_client.describe_instances(**kwargs)

    for reservation in response['Reservations']:
      for instance in reservation['Instances']:
        # Instance id
        # Instance Tag - Name
        # Volume
        # security group
        # network interface
        dependent_info['InstanceId'] = instance['InstanceId']
        tags = instance['Tags'] 
        if 'Tags' in instance:
          dependent_info['InstanceName'] = self.get_tag_value_from_tags(tags,'Name')
          dependent_info['InstanceTagProduct'] = self.get_tag_value_from_tags(tags,'product')
          dependent_info['InstanceTagService'] = self.get_tag_value_from_tags(tags,'service')
        else:
          dependent_info['InstanceName'] = None
          dependent_info['InstanceTagProduct'] = None
          dependent_info['InstanceTagService'] = None
          
        security_group_ids = []
        for security_group in instance['SecurityGroups']:
          security_group_ids.append(security_group['GroupId'])

        security_groups_info = []
        for security_group_id in security_group_ids:
          security_groups_info.append(self.get_security_group_info(security_group_id))

        dependent_info['SecurityGroups'] = security_groups_info
        
        network_interface_ids = []
        for network_interface in instance['NetworkInterfaces']:
          network_interface_ids.append(network_interface['NetworkInterfaceId'])
        
        network_interfaces_info = []
        for network_interface_id in network_interface_ids:
          network_interfaces_info.append(self.get_network_interface_info(network_interface_id))

        dependent_info['NetworkInterfaces'] = network_interfaces_info
        
        volume_ids = []
        for block_device in instance['BlockDeviceMappings']:
          volume_ids.append(block_device['Ebs']['VolumeId'])
        
        volumes_info = []
        for volume_id in volume_ids:
          volumes_info.append(self.get_volume_info(volume_id))
          
        dependent_info["BlockDeviceMappings"] = volumes_info
     
    return dependent_info   
      

  def get_indent(self, num_indents = 2):
    indent_string = '          '
    indent_string_len = len(indent_string)
    if num_indents > indent_string_len :
      num_indents = indent_string_len
    return indent_string[0:num_indents]
    
  def pretty_print(self, dependent_info = None):
    if dependent_info:
      
      print "Instance Name {0} Instance Id {1}".format(dependent_info['InstanceName'],dependent_info['InstanceId'] )
      print "{0} product: {1} service: {2}".format(self.get_indent(2),
                                                    dependent_info['InstanceTagProduct'],
                                                    dependent_info['InstanceTagService'])
      
      print ""
      
      for security_group in dependent_info['SecurityGroups']:
        print "{0} Security Group Name  {1} Security Group {2}".format(self.get_indent(2),
                                                                      security_group['SecurityGroupName'],
                                                                      security_group['SecurityGroupId'])
        print "{0} product: {1} service: {2}".format(self.get_indent(4),
                                                    security_group['SecurityTagProduct'],
                                                    security_group['SecurityTagService'])
                                                    
      print ""

      for network_interface in dependent_info['NetworkInterfaces']:
        print "{0} Network Interface {1} Network Interface Description {2}".format(self.get_indent(2),
                                                                      network_interface['NetworkInterfaceId'],
                                                                      network_interface['NetworkInterfaceDescription'])
        print "{0} product: {1} service: {2}".format(self.get_indent(4),
                                                    network_interface['NetworkInterfaceTagProduct'],
                                                    network_interface['NetworkInterfaceTagService'])
        
      print ""
      
      for volume_info in dependent_info["BlockDeviceMappings"]:
        print "{0} Volume ID {1}".format( self.get_indent(2),
                                          volume_info['VolumeId'])
        print "{0} product: {1} service: {2}".format(self.get_indent(4),
                                                    volume_info['VolumeTagProduct'],
                                                    volume_info['VolumeTagService'])
        
      print ""

      ## ElasticBeanstalk connection Tag 'elasticbeanstalk:environment-id'  
#
# Main processing       
#

ec2_client = boto3.client('ec2','us-west-2')
  
ec2_info = EC2_info()    

args = sys.argv

instance_ids = ec2_info.get_matching_instance_ids(args[1])
dependents_info = ec2_info.get_dependent_information_for_ec2_instances(instance_ids)
for dependent_info in dependents_info:
  ec2_info.pretty_print(dependent_info)


