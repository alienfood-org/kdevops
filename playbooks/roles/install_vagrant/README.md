install-vagrant
===============

The Ansible install-vagrant role lets you get install Vagrant, and on Linux
also installs the vagrant-libvirt plugin.

Requirements
------------

Run a supported OS/distribution:

  * SUSE SLE / OpenSUSE
  * Red Hat / Fedora
  * Debian / Ubuntu

Role Variables
--------------

  * vagrant_version: the Vagrant version to install. This is only used if
    downloading and installing the zip file.
  * force_install_zip: if your distro supports a package ignore it, and instead
    installt he package from the zip file directly from HashiCorp
  * force_install_if_present: set to False by default, set this to True to
    force download Vagrant even if you already have it present.

Dependencies
------------

None.

Example Playbook
----------------

Below is an example playbook, say a bootlinux.yml file:

```
---
- hosts: localhost
  roles:
    - role: mcgrof.install-vagrant
```

License
-------

copyleft-next-0.3.1
