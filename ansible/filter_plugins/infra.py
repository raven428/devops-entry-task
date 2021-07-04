# infrastructure filters
import pickle
import pprint
import ansible.utils.display
import ansible.plugins.filter.core
display = ansible.utils.display.Display()
pp = pprint.PrettyPrinter(
  indent=2,
  width=10,
  compact=False,
)


def warn_by_suffixes(suffixes, hostvars, prefix, action):
  for var_name, var_value in hostvars.items():
    if var_name.find(prefix) != 0:
      continue
    var_name_suffix = var_name.replace(prefix, '', 1)
    if not var_name_suffix in suffixes:
      display.warning(
        'missed variable [%s] while mass %s' % (var_name, action)
      )


def join_by_suffixes(suffixes, hostvars, prefix, suppress_warning=False):
  res = ''
  prefix = prefix + '_'
  for suffix in suffixes:
    try:
      res += hostvars[prefix + suffix]
    except KeyError:
      pass
  if not suppress_warning:
    warn_by_suffixes(suffixes, hostvars, prefix, 'union')
  return (res)


def union_by_suffixes(suffixes, hostvars, prefix, suppress_warning=False):
  res = []
  prefix = prefix + '_'
  for suffix in suffixes:
    try:
      res += hostvars[prefix + suffix]
    except KeyError:
      pass
  if not suppress_warning:
    warn_by_suffixes(suffixes, hostvars, prefix, 'union')
  return (res)


def combine_by_suffixes(
  suffixes, hostvars, prefix, suppress_warning=False, combine_options={}
):
  res = {}
  prefix = prefix + '_'
  for suffix in suffixes:
    if prefix + suffix in hostvars:
      res = ansible.plugins.filter.core.combine(
        res,
        hostvars[prefix + suffix],
        **combine_options,
      )
  if not suppress_warning:
    warn_by_suffixes(suffixes, hostvars, prefix, 'combine')
  return (res)


def inv2ptrgt(groups={}, hostvars={}):
  global inv2ptrgt_res
  try:
    return (inv2ptrgt_res[pickle.dumps(groups) + pickle.dumps(hostvars)])
  except NameError:
    inv2ptrgt_res = {}
  except KeyError:
    pass
  res = {}
  for group in groups:
    if group.find('ptrgt_') != 0:
      continue
    target_name_orig = group.replace('ptrgt_', '', 1)
    target_name = target_name_orig.replace('_', '-')
    res[target_name] = []
    for ptrgt in sorted(groups[group]):
      target_data = {}
      target_data['targets'] = ['']
      try:
        target_data['targets'][0] = hostvars[ptrgt][target_name_orig][
          'scrape_addr']
      except KeyError:
        try:
          target_data['targets'][0] = hostvars[ptrgt]['scrape_addr']
        except KeyError:
          try:
            target_data['targets'][0] = hostvars[ptrgt]['ansible_host']
          except KeyError:
            display.warning(
              'couldn\'t find neither [ansible_host] nor [scrape_addr] keys in [%s] inventory item'
              % (ptrgt)
            )
            pass
      target_data['targets'][0] += ':'
      try:
        target_data['targets'][0] += str(
          hostvars[ptrgt][target_name_orig + '_scrape_port']
        )
      except KeyError:
        try:
          target_data['targets'][0] += str(
            hostvars[ptrgt][target_name_orig]['scrape_port']
          )
        except KeyError:
          try:
            target_data['targets'][0] += str(hostvars[ptrgt]['scrape_port'])
          except KeyError:
            target_data['targets'][0] += '9100'
      target_data['labels'] = {}
      target_data['labels']['nick'] = hostvars[ptrgt]['inventory_hostname']
      target_vars = {}
      try:
        target_vars = hostvars[ptrgt]
      except KeyError:
        pass
      try:
        target_vars = {
          **target_vars,
          **hostvars[ptrgt][target_name_orig]
        }
      except KeyError:
        pass
      global labels
      labels = {}
      for target_var in target_vars:
        if target_var.find('plabel_') != 0:
          continue
        varname_orig = target_var.replace('plabel_', '', 1)
        labels[varname_orig.replace('_', '-')] = target_vars[target_var]
        target_data['labels'][varname_orig.replace(
          '_',
          '-',
        )] = target_vars[target_var]
      for target_var in target_vars:
        if target_var.find(target_name_orig + '_plabel_') != 0:
          continue
        varname_orig = target_var.replace(
          target_name_orig + '_plabel_',
          '',
          1,
        )
        labels[varname_orig.replace('_', '-')] = target_vars[target_var]
        target_data['labels'][varname_orig.replace(
          '_',
          '-',
        )] = target_vars[target_var]
      res[target_name].append(target_data)
  inv2ptrgt_res[pickle.dumps(groups) + pickle.dumps(hostvars)] = res
  return (res)


def inv2scrape(groups={}, hostvars={}):
  global inv2scrape_res
  try:
    return (inv2scrape_res[pickle.dumps(groups) + pickle.dumps(hostvars)])
  except NameError:
    inv2scrape_res = {}
  except KeyError:
    pass
  global labels
  inv2ptrgt(groups, hostvars)
  res = []
  for group in groups:
    if group.find('ptrgt_') != 0:
      continue
    target_name_orig = group.replace('ptrgt_', '', 1)
    target_name = target_name_orig.replace('_', '-')
    scrape_config = {}
    scrape_config['job_name'] = target_name
    scrape_config['file_sd_configs'] = [{
      'files': ['/etc/prometheus/file_sd/' + target_name + '.yml']
    }]
    host0 = groups[group][0]
    try:
      scrape_config = {
        **scrape_config,
        **hostvars[host0]['scrape_config'],
      }
    except KeyError:
      pass
    try:
      scrape_config = {
        **scrape_config,
        **hostvars[host0][target_name_orig]['scrape_config'],
      }
    except KeyError:
      pass
    # drop all added labels to save database space
    # timeseries like 'up' will not be affected
    try:
      scrape_config['metric_relabel_configs']
    except KeyError:
      scrape_config['metric_relabel_configs'] = []
    for label in list(labels.keys()) + ['job']:
      # leave 'cluster' label for ceph
      if label in ['cluster'] and target_name.find('ceph-') == 0:
        continue
      scrape_config['metric_relabel_configs'].append({
        'regex': '^\Q' + label + '\E$',
        'action': 'labeldrop',
      })
    res.append(scrape_config)
  inv2scrape_res[pickle.dumps(groups) + pickle.dumps(hostvars)] = res
  return (res)


class FilterModule(object):
  def filters(self):
    return {
      'inv2ptrgt': inv2ptrgt,
      'inv2scrape': inv2scrape,
      'join_by_suffixes': join_by_suffixes,
      'union_by_suffixes': union_by_suffixes,
      'combine_by_suffixes': combine_by_suffixes,
    }
