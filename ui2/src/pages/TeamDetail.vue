<template>
  <div v-loading="asyncLoading">
    <h1><small>Entry no. {{ team.id }} - {{ team.organization }}</small> {{ team.name }}</h1>
    <div class="members d-flex justify-content-around flex-wrap">
      <div v-for="member in team.members" class="item d-flex flex-column justify-content-center">
        <div class="name">{{ member.name }}</div>
        <div class="login">{{ member.login }}</div>
      </div>
    </div>
    <div v-if="isAdmin" class="problems">
      <template v-for="problem in problems" class="item">
        <router-link
          :to="{ name: 'problem-answers', params: { team: id, id: problem.id} }"
          class="d-flex item">
          <div class="id">{{ problem.id }}</div>
          <div class="title">{{ problem.title }}</div>
          <div class="score">{{ point(problem.id) }} 点</div>
        </router-link>
      </template>
    </div>
    <!--<pre>{{ team }}</pre>-->
  </div>
</template>

<style scoped>
.members .item {
  width: 10rem;
  height: 10rem;
  margin: 2rem;
  background: #ddd;
  text-align: center;
  border-radius: 50%;
  font-size: 1.2rem;
}
.members  .item .name {
  font-size: 1.1em;
  font-weight: bold;
}

.problems {
  max-width: 600px;
  margin: auto;
}
.problems .item {
  border-bottom: 1px solid #FDBBCC;
  color: inherit;
  padding: .5rem;
}
.problems .item > * {
  flex-grow: 1;
}
.problems .item .id {
  flex-basis: 3rem;
  flex-grow: 0;
}
.problems .item .score {
  text-align: right;
}
</style>

<script>
import { SET_TITLE } from '../store/'
import { API } from '../utils/Api'
import { mapGetters } from 'vuex'
import { latestAnswer } from '../utils/Filters'

export default {
  name: 'team-detail',
  data () {
    return {
    }
  },
  asyncData: {
    teamDefault: {},
    team () {
      return API.getTeam(this.id);
    },
    problemsDefault: {},
    problems () {
      return API.getProblems();
    },
  },
  computed: {
    id () {
      return this.$route.params.id;
    },
    ...mapGetters([
      'isAdmin',
    ]),
  },
  watch: {
  },
  mounted () {
    this.$store.dispatch(SET_TITLE, 'チーム詳細');
  },
  destroyed () {
  },
  methods: {
    point (problemId) {
      try {
        return ((e) => e.score ? e.score.subtotal_point : 0)(latestAnswer(
          this.team.answers.filter(ans => ans.problem_id === problemId)))
      } catch (e) {
        return '---'
      }
    }
  },
}
</script>

