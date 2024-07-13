local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.gitlab_scheduled_merge;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('gitlab-scheduled-merge', params.namespace);

{
  'gitlab-scheduled-merge': app,
}
