# MediCore A4 Kubernetes Configuration

## Deployment Design

The Kubernetes Deployment uses two replicas because DTS206 A4 explicitly requires two application replicas.

`apps/v1` is used because Deployment is a workload resource provided by the Apps API.

The selector and Pod labels both use `app: medicore-a4` so that the Deployment can identify the Pods it owns and the Service can forward traffic to the same application workload.

A RollingUpdate strategy is used so updates can occur without deliberately removing all healthy application replicas.

`maxUnavailable: 0` prevents the rollout controller from intentionally reducing the desired healthy replica count during an update.

`maxSurge: 1` allows one temporary additional Pod while a new version becomes ready.

## Kubernetes Security Context

`automountServiceAccountToken: false` is set because the MediCore demonstration application does not require access to the Kubernetes API. Not mounting an unnecessary API credential reduces credential exposure.

`runAsNonRoot: true` ensures Kubernetes refuses to run the container as root.

`runAsUser: 1001` and `runAsGroup: 1001` match the non-root `appuser` created in the Docker image.

`fsGroup: 1001` permits the application identity to access appropriate mounted files without changing the primary process to root.

`seccompProfile: RuntimeDefault` applies the container runtime's default syscall filtering profile.

At container level, `allowPrivilegeEscalation: false` prevents a process from gaining additional privileges.

`readOnlyRootFilesystem: true` prevents runtime modification of the application image.

All Linux capabilities are dropped because this HTTP application does not require privileged kernel operations.

## Resources

Each Pod requests:

- CPU: `100m`
- Memory: `128Mi`

Each Pod is limited to:

- CPU: `500m`
- Memory: `256Mi`

Requests allow the Kubernetes scheduler to reserve appropriate capacity.

Limits prevent one application Pod from consuming excessive resources and impacting other services.

## Health Probes

The liveness probe calls:

`GET /health`

A failed liveness probe allows Kubernetes to restart a failed container.

The readiness probe also calls:

`GET /health`

A Pod that fails readiness is removed from Service traffic until it becomes healthy again.

## Read-Only Filesystem

The application root filesystem is read-only.

Gunicorn requires temporary writable space, therefore an `emptyDir` volume is mounted only at `/tmp`.

The temporary volume is memory-backed and limited to `64Mi`.

This maintains the immutable-root design without preventing the application from operating normally.

## Secrets

The database password is represented by a Kubernetes Secret named:

`medicore-db-password`

The secret is mounted as a file:

`/run/secrets/db_password`

The actual password is not written into `deployment.yaml` or committed to Git.

## NodePort

The Service uses:

`type: NodePort`

because the assignment explicitly requires NodePort when demonstrating the workload using Minikube.

The service exposes:

`30080`

and forwards requests to container port `8080`.

## Self-Healing

The Deployment controller continuously reconciles actual replica count against:

`replicas: 2`

Deleting one Pod therefore causes the controller to create a replacement Pod.

The replacement must have a different generated Pod name. A same-name container restart would not demonstrate Kubernetes Deployment self-healing.