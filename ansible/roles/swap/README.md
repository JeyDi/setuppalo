# Create_swap Role

## Description

This Ansible role creates a 30GB swap file at `/data/swapfile`, configures it with appropriate permissions, and ensures it is enabled and persistent across reboots.

## Variables

- `swap_file_path` (default: `/data/swapfile`): Path where the swap file will be created.
- `swap_file_size` (default: `30`): Size of the swap file in GB.

## Usage

Add the role to your playbook:

```yaml
- hosts: all
  roles:
    - create_swap

---

## **Usage in a Playbook**

Here’s how you include the role in a playbook:
```yaml
- hosts: all
  become: true
  roles:
    - role: create_swap