# Lab 12: Managing Configuration and Sensitive Data with ConfigMaps and Secrets

- **Environment:** Killercoda Kubernetes playground, controlplane tab, namespace `ivolve` from Lab 11 (recreate it with `kubectl create namespace ivolve` if the playground is new).
- **Note on names:** the slide writes `ivolveCM` and `ivolveSecret`, Kubernetes only accepts lowercase names, so the real objects are `ivolvecm` and `ivolvesecret`.
- **Values:** DB_HOST `mysql` (the headless Service of the MySQL StatefulSet), DB_USER `ivolve`, MYSQL_ROOT_PASSWORD `RootPass123`, DB_PASSWORD `ivolve123`.

## Lab Tasks

- [ ] Create a ConfigMap named `ivolveCM` in the ivolve namespace to store the non-sensitive MySQL configuration variables `DB_HOST` and `DB_USER`.
- [ ] Create a Secret named `ivolveSecret` in the ivolve namespace to store `MYSQL_ROOT_PASSWORD` and `DB_PASSWORD`.
- [ ] Use Base64 encoding to encode the Secret data values when defining the Secret using a YAML manifest.

## Screenshot Moments

| File | What it shows |
|---|---|
| `images/lab12-instructions.png` | The lab slide |
| `images/lab12-configmap.png` | The ConfigMap created with DB_HOST and DB_USER |
| `images/lab12-base64.png` | The two passwords encoded with `echo -n ... \| base64` |
| `images/lab12-yaml.png` | The secret.yaml manifest in the editor with the base64 values |
| `images/lab12-secret.png` | The Secret created, `kubectl get ... -o yaml` showing the base64 data |
