<template>
  <div>
    <ul class="nav nav-tabs">
      <li class="nav-item">
        <router-link :to="{name: 'problem-issues', params: {id: problemId, team: teamId}}" class="nav-link" active-class="active">
          質問
        </router-link>
      </li>
      <li class="nav-item">
        <router-link :to="{name: 'problem-answers', params: {id: problemId, team: teamId}}" class="nav-link"  active-class="active">
          解答
        </router-link>
      </li>
      <li class="score">
        得点: <span class="point">{{ point }}</span>
      </li>
    </ul>
  </div>
</template>

<style scoped>
.nav {
  margin: 1rem 0 3rem;
}
.score {
  margin: 0 0 0 auto;
  font-weight: bold;
  font-size: 1.5rem;
}
.score .point {
  color: #E6003B;
}
</style>

<script>
import { SET_TITLE } from '../store/'
import { latestAnswer } from '../utils/Filters'

export default {
  name: 'problem-mode-switch',
  props: {
    problemId: String,
    teamId: String,
    answers: Array,
  },
  data () {
    return {
    }
  },
  asyncData: {
  },
  computed: {
    currentAnswers () {
      return this.answers
        .filter(i => '' + i.problem_id === this.problemId)
        .filter(i => '' + i.team_id === this.teamId)
    },
    point () {
      return ((e) => e.score ? e.score.subtotal_point : 0)(latestAnswer(this.currentAnswers))
    },
  },
  watch: {
  },
  mounted () {
    this.$store.dispatch(SET_TITLE, 'ページ名');
  },
  destroyed () {
  },
  methods: {
  },
}
</script>

