import * as superagent from 'superagent';
import { Emit, AUTH_ERROR } from '../utils/EventBus'

async function RequestMiddleware (request, ignoreAuthError = false) {
  if (request.url[0] !== '/' || request.url.startsWith('http')) {
    request.url = '/api/' + request.url;
  }
  request.set('Content-Type', 'application/json');

  try {
    return await request;
  } catch (err) {
    if ((err.status === 401 || err.status === 403) && !ignoreAuthError) {
      Emit(AUTH_ERROR, err);
    }
    throw err;
  }
}

export class API {
  // session
  static login (login, password, req = superagent) {
    return RequestMiddleware(req
      .post('session')
      .send(JSON.stringify({
        login,
        password,
      })), true
    ).then(res => res.body)
  }
  static logout (req = superagent) {
    return RequestMiddleware(req.del('session'))
  }
  static getSession (req = superagent) {
    return RequestMiddleware(req.get('session?with=member-team'))
      .then(res => res.body)
  }
  static getNotices (req = superagent) {
    return RequestMiddleware(req.get('notices'))
      .then(res => res.body)
  }

  // notices
  static postNotices (title, text, pinned = false, req = superagent) {
    return RequestMiddleware(
      req.post('notices')
        .send(JSON.stringify({
          title,
          text,
          pinned,
          body: '',
        }))
    ).then(res => res.body)
  }
  static deleteNotices (id, req = superagent) {
    return RequestMiddleware(req.del(`notices/${id}`))
      .then(res => res.body)
  }
  static getNotifications (req = superagent) {
    return RequestMiddleware(req.get('notifications'))
      .then(res => res.body)
  }

  // members
  static getMembers (req = superagent) {
    return RequestMiddleware(req.get('members?with=team'))
      .then(res => res.body)
  }
  static postMembers (login, name, password, registration_code, req = superagent) {
    return RequestMiddleware(
      req.post('members')
        .send(JSON.stringify({ login, name, password, registration_code }))
    ).then(res => res.body)
  }

  // teams
  static getTeams (req = superagent) {
    return RequestMiddleware(req.get('teams'))
      .then(res => res.body)
  }
  static getTeamsWithScore (req = superagent) {
    return RequestMiddleware(req.get(`teams?with=answers-score`))
      .then(res => res.body)
  }
  static addTeams (name, organization, regCode, req = superagent) {
    return RequestMiddleware(
      req.post('teams')
        .send(JSON.stringify({
          name,
          organization,
          registration_code: regCode,
        }))
    ).then(res => res.body)
  }
  static getTeam (id, req = superagent) {
    return RequestMiddleware(req.get(`teams/${id}?with=members,answers-score`))
      .then(res => res.body)
  }
  static getTeamWithAnswersComments (id, req = superagent) {
    return RequestMiddleware(req.get(`teams/${id}?with=members,answers-score,answers-member`))
      .then(res => res.body)
  }
  static getTeamWithAnswers (id, req = superagent) {
    return RequestMiddleware(req.get(`teams/${id}?with=members,answers-score`))
      .then(res => res.body)
  }
  static getTeamWithIssues (id, req = superagent) {
    return RequestMiddleware(req.get(`teams/${id}?with=members,answers-score,answers-member`))
      .then(res => res.body)
  }
  // 補足説明の追加
  static postAnswersComments (problemId, text, req = superagent) {
    return RequestMiddleware(
      req.post(`problems/${problemId}/comments`)
        .send(JSON.stringify({
          text,
        }))
    ).then(res => res.body)
  }
  static deleteAnswersComments (problemId, id, req = superagent) {
    return RequestMiddleware(
      req.del(`problems/${problemId}/comments/${id}`)
    ).then(res => res.body)
  }

  // scoreboard
  static getScoreboard (req = superagent) {
    return RequestMiddleware(req.get(`scoreboard`))
      .then(res => res.body)
  }

  // contest
  static getContest (req = superagent) {
    return RequestMiddleware(req.get(`contest`))
      .then(res => res.body)
  }

  // groups
  static postProblemGroup (obj, req = superagent) {
    return RequestMiddleware(
      req.post(`problem_groups`)
        .send(JSON.stringify(obj))
    ).then(res => res.body)
  }

  // problems
  static getProblemGroups (req = superagent) {
    return RequestMiddleware(req.get(`problem_groups`))
      .then(res => res.body)
  }
  static getProblemsWithScore (req = superagent) {
    return RequestMiddleware(req.get(`problems?with=answers-score,creator`))
      .then(res => res.body)
  }
  static getProblems (req = superagent) {
    return RequestMiddleware(req.get(`problems`))
      .then(res => res.body)
  }
  static postProblems (obj, req = superagent) {
    return RequestMiddleware(
      req.post(`problems`)
        .send(JSON.stringify(obj))
    ).then(res => res.body)
  }
  static getProblem (id, req = superagent) {
    return RequestMiddleware(req.get(`problems/${id}?with=comments,creator`))
      .then(res => res.body)
  }
  static patchProblem (id, obj, req = superagent) {
    return RequestMiddleware(
      req.patch(`problems/${id}`)
        .send(JSON.stringify(obj))
    ).then(res => res.body)
  }

  // issues
  static getIssues (req = superagent) {
    return RequestMiddleware(req.get(`issues`))
      .then(res => res.body)
  }
  static getIssuesWithComments (req = superagent) {
    return RequestMiddleware(req.get(`issues?with=comments-member-team,team,problem`))
      .then(res => res.body)
  }
  static getIssue (id, req = superagent) {
    return RequestMiddleware(req.get(`issues/${id}?with=comments-member-team,team,problem`))
      .then(res => res.body)
  }
  static addIssues (problem_id, title, req = superagent) {
    return RequestMiddleware(
      req.post(`issues`)
        .send(JSON.stringify({ problem_id, title }))
    ).then(res => res.body)
  }
  static patchIssues (id, obj, req = superagent) {
    return RequestMiddleware(
      req.patch(`issues/${id}`).send(JSON.stringify(obj))
    ).then(res => res.body)
  }
  static addIssueComment (issueId, text, req = superagent) {
    return RequestMiddleware(
      req.post(`issues/${issueId}/comments`)
        .send(JSON.stringify({ text }))
    ).then(res => res.body)
  }

  // answers
  static getAnswers (req = superagent) {
    return RequestMiddleware(req.get(`answers`))
      .then(res => res.body)
  }
  static getAnswer (id, req = superagent) {
    return RequestMiddleware(req.get(`answers/${id}?with=score`))
      .then(res => res.body)
  }
  static postAnswer (answerId, text, req = superagent) {
    return RequestMiddleware(
      req.post(`problems/${answerId}/answers`)
        .send(JSON.stringify({ text }))
    ).then(res => res.body)
  }
  static patchAnswers (id, obj, req = superagent) {
    return RequestMiddleware(req.patch(`answers/${id}`).send(JSON.stringify(obj)))
      .then(res => res.body)
  }

  // scores
  static getScores (req = superagent) {
    return RequestMiddleware(req.get(`scores`))
      .then(res => res.body)
  }
  static getScore (id, req = superagent) {
    return RequestMiddleware(req.get(`scores/${id}`))
      .then(res => res.body)
  }
  static postScore (answer_id, point, solved, req = superagent) {
    return RequestMiddleware(
      req.post(`scores`)
        .send(JSON.stringify({
          answer_id,
          point,
          solved,
        }))
    ).then(res => res.body)
  }
  static putScore (id, obj, req = superagent) {
    return RequestMiddleware(req.put(`scores/${id}`).send(JSON.stringify(obj)))
      .then(res => res.body)
  }
}
