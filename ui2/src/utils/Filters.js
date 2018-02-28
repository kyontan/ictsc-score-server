import dateformat from 'dateformat';
import * as d3 from 'd3';
import moment from 'moment';

export function fullDateFilter (value) {
  var fmtStr = 'yyyy/mm/dd HH:MM'
  try {
    if (value === 0 || value === undefined) {
      return '----/--/-- --:--';
    } else if (typeof value === 'number') {
      return dateformat(new Date(value), fmtStr)
    } else {
      return dateformat(new Date(value), fmtStr)
    }
  } catch (e) {
    console.error('Filters/fullDate', e, value);
    return '----/--/-- --:--';
  }
}

export function countFilter (value) {
  return d3.format(',')(value);
}
export function prefixCountFilter (value) {
  if (value < 1) {
    return d3.format('.2')(value)
  } else {
    return d3.format(',.2s')(value);
  }
}
export function percentageFilter (value) {
  return d3.format('.2f')(value) + '%';  // like: 100.00%
}

export function issueStatus (issue) {
  // 未回答: 1  対応中: 2  解決済: 3
  if (!issue) return 0;
  if (issue.closed) return 3;
  if (!issue.comments) return 0;
  if (issue.comments.length < 2) return 1;

  var lastComment = issue.comments[issue.comments.length - 1];
  // memberが居ない => readableではないユーザ (上位ユーザ)
  if (!lastComment.member) return 2;

  if (lastComment.member.role_id === 4) return 1;
  return 2;
}

export function dateRelative (date) {
  return moment(date)
    .lang('ja')
    .fromNow();
}

export function tickDuration (date) {
  return moment.utc(date)
    .format('HH:mm:ss')
}

export function latestAnswer (ans) {
  return ans ? ans.reduce((p, n) => Date.parse(p.updated_at) < Date.parse(n.updated_at) ? n : p, {updated_at: 0}) : ans;
}
