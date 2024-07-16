// main template for gitlab-scheduled-merge
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.gitlab_scheduled_merge;
local instanceName = inv.parameters._instance;

local namespace = kube.Namespace(params.namespace) {
  metadata+: {
    labels+: params.namespaceLabels,
  },
};

local secret = kube.Secret(instanceName) {
  metadata+: {
    labels+: {
      'app.kubernetes.io/instance': instanceName,
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'gitlab-scheduled-merge',
    },
  },
  stringData: {
    accessToken: params.accessToken,
  },
};

local deployment = kube.Deployment(instanceName) {
  metadata+: {
    labels+: {
      'app.kubernetes.io/instance': instanceName,
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'gitlab-scheduled-merge',
    },
    namespace: params.namespace,
  },
  spec+: {
    replicas: 1,
    selector: {
      app: instanceName,
    },
    template+: {
      metadata: {
        labels: {
          app: instanceName,
        },
      },
      spec+: {
        serviceAccountName: 'default',
        securityContext: {
          seccompProfile: { type: 'RuntimeDefault' },
        },
        containers_:: {
          default: kube.Container('scheduled-merge') {
            image: '%(registry)s/%(repository)s:%(tag)s' % params.images.scheduledmerge,
            args_:: {
              'gitlab-token': '$(ACCESS_TOKEN)',
              'gitlab-base-url': params.gitlabAPI,
            },
            env_:: {
              ACCESS_TOKEN: { secretKeyRef: { name: secret.metadata.name, key: 'accessToken' } },
            },
            resources: params.resources,
            securityContext: {
              allowPrivilegeEscalation: false,
              capabilities: { drop: [ 'ALL' ] },
            },
          },
        },
      },
    },
  },
};


// Define outputs below
{
  '00_namespace': namespace,
  '10_secret': secret,
  '20_deployment': deployment,
}
