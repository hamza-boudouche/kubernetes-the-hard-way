from jinja2 import Template
import configparser

# Parse the inventory file
inventory = configparser.ConfigParser(allow_no_value=True)
inventory.read('private_inventory.ini')

ports = configparser.ConfigParser()
ports.read('service_ports.ini')

# print(dict(ports["all"]))

# print(list(inventory['workers']))

# Load the template file
with open('16-lb/nginx.conf.j2', 'r') as f:
    template = Template(f.read())

    # Render the template with the variables
    output = template.render(port_config=dict(ports["all"]), workers=list(
        inventory['workers']), backend='192.168.1.100')

    # Print the rendered template
    print(output)
