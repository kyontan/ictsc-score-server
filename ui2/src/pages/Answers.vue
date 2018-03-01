<template>
  <div v-loading="asyncLoading">
    <h1>解答と採点</h1>
    <div class="description">
      <p>このページは解答一覧画面です。下のボタンを切り替えることで、表示される種類が絞り込めます。</p>
    </div>
    <div class="tools">
      <button v-on:click="filterSelect = 0" :class="{ active: filterSelect == 0 }" class="btn label-secondary">全て表示</button>
      <button v-on:click="filterSelect ^= 1" :class="{ active: filterSelect & 1 }" class="btn label-warning">未提出</button>
      <button v-on:click="filterSelect ^= 2" :class="{ active: filterSelect & 2 }" class="btn label-danger">未採点</button>
      <button v-on:click="filterSelect ^= 4" :class="{ active: filterSelect & 4 }" class="btn label-success">採点済</button>
    </div>
    <div class="problems">
      <div v-for="problem in problems" v-if="anyMatchesFilter(problem.answers, problem.id)" class="problem">
        <h3>{{ problem.title }}</h3>
        <small>
          基準点: {{ problem.reference_point }} /
          満点: {{ problem.perfect_point }} /
          正解チーム数: {{ problem.solved_teams_count }}
          担当者: {{ problem.creator.name }}
          </small>
        <div class="teams row">
          <div v-for="team in teams" v-if="matchesFilter(problem.answers, team.id, problem.id)" class="col-3">
            <router-link
              :to="{name: 'problem-answers', params: {id: problem.id, team: team.id}}"
              :class="'team status-' + status(problem.answers, team.id, problem.id)">
              {{ team.id }}. {{ team.name }} {{ score(problem.answers, team.id, problem.id) }}点
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.problem {
  margin-bottom: 3rem;
}
.problems h3 {
  display: inline-block;
  margin-right: 1rem;
  margin-bottom: 1rem;
}
.problems h3 small {
  font-size: .7em;
  margin-left: 2rem;
}
.team {
  padding: .3rem;
  margin-bottom: .5rem;
  border: 1px solid #ddd;
  background: #aaa;
  border-radius: 5px;
  display: block;
}
.team.status-1 {
  background: #F1F7A6;
  color: #8DA700;
}
.team.status-2 {
  background: #FFB1BC;
  color: #F00000;
}
.team.status-4 {
  background: #CBF5E0;
  color: #00A353;
}

.tools {
  text-align: center;
  margin: 3rem 0;
}
.tools button {
  display: inline-block;
  margin: .3rem;
  padding-right: 5rem;
  padding-left: 5rem;
}
</style>

<script>
import { SET_TITLE } from '../store/'
import { API } from '../utils/Api'

export default {
  name: 'answers',
  data () {
    return {
      filterSelect: 0,
    }
  },
  asyncData: {
    problemsDefault: [],
    problems () {
      return API.getProblemsWithScore();
    },
    teamsDefault: [],
    teams () {
      return API.getTeams();
    },
  },
  computed: {
  },
  watch: {
  },
  mounted () {
    this.$store.dispatch(SET_TITLE, '解答と採点');
  },
  destroyed () {
  },
  methods: {
    anyMatchesFilter (answers, problemId) {
      return !!this.teams.find(team => this.matchesFilter(answers, team.id, problemId))
    },
    matchesFilter (answers, teamId, problemId) {
      let answer_status = this.status(answers, teamId, problemId);
      return !this.filterSelect ||
        (this.filterSelect & 1) === answer_status ||
        (this.filterSelect & 2) === answer_status ||
        (this.filterSelect & 4) === answer_status;
    },
    teamAnswers (answers, teamId, problemId) {
      if (answers === undefined) return [];
      return answers.filter(ans => ans.team_id === teamId && ans.problem_id === problemId);
    },
    status (answers, teamId, problemId) {
      // 1 未回答  2 未採点  4 採点済み
      var teamAnswers = this.teamAnswers(answers, teamId, problemId);
      if (teamAnswers.length === 0) return 1;
      return teamAnswers
        .reduce((p, n) => Math.min(p, n.score ? 4 : 2), 4);
    },
    score (answers, teamId, problemId) {
      return this.teamAnswers(answers, teamId, problemId)
        .reduce((p, n) => p + (n.score ? n.score.subtotal_point : 0), 0)
    },
  },
}
</script>

