# Projects Directory

This directory is mounted from the host and persists across container restarts.

## Usage

1. **Copy your SDN projects here** from the host:
   ```bash
   # From host machine
   cp -r /path/to/your/sdn/project ./projects/
   ```

2. **Access from inside container**:
   ```bash
   # Inside container
   cd /app/projects/your-project
   ```

3. **File persistence**: Any files created or modified here will persist when the container is stopped and restarted.

## Example Projects

Check the `../examples/` directory for:
- `simple_controller.py` - Basic SDN controller
- `simple_topology.py` - Example network topology

Copy these to experiment:
```bash
# Inside container
cp /app/examples/* /app/projects/
cd /app/projects
```

## Best Practices

- **Organize by project**: Create subdirectories for different SDN projects
- **Use version control**: Initialize git repositories for your projects
- **Document your work**: Include README files for each project
- **Test incrementally**: Start with simple examples before complex implementations

## Directory Structure Example

```
projects/
├── my-sdn-controller/
│   ├── controller.py
│   ├── topology.py
│   ├── requirements.txt
│   └── README.md
├── load-balancer/
│   ├── lb_controller.py
│   ├── test_topology.py
│   └── web/
└── experiments/
    ├── experiment1.py
    └── results/
```