#|
  Copyright (C) 2025 ironmoon <me@ironmoon.dev>

  This file is part of pyret-autograder-pawtograder.

  pyret-autograder-pawtograder is free software: you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public License as
  published by the Free Software Foundation, either version 3 of the License,
  or (at your option) any later version.

  pyret-autograder-pawtograder is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser
  General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  with pyret-autograder-pawtograder. If not, see <http://www.gnu.org/licenses/>.
|#
import lists as L
import json as J
import string-dict as SD

import npm("pyret-autograder", "main.arr") as A

provide:
  prepare-for-pawtograder
end

fun add(sd :: SD.MutableStringDict, key :: String, val, trans):
  if (is-Option(val)) block:
    cases (Option) val:
      | none => nothing
      | some(v) => sd.set-now(key, trans(v))
    end
  else:
    sd.set-now(key, trans(val))
  end
end

fun map-json(trans):
  lam(lst):
    L.map(trans, lst) ^ J.j-arr
  end
end

fun num-to-json(num :: Number) -> J.JSON:
  if num-is-fixnum(num) or num-is-roughnum(num):
    J.to-json(num)
  else:
    J.to-json(num-to-roughnum(num))
  end
end

data PawtograderFeedback:
  | pawtograder-feedback(
    tests :: L.List<PawtograderTest>,
    lint :: PawtograderLint,
    output :: PawtograderTopLevelOutput,
    max-score :: Option<Number>,
    score :: Option<Number>,
    artifacts :: L.List<PawtograderArtifact>,
    annotations :: L.List<PawtograderAnnotations>) with:
  method to-json(self) -> J.JSON block:
    sd = [SD.mutable-string-dict:]
    shadow add = add(sd, _, _, _)
    add("tests", self.tests, map-json(_.to-json()))
    add("lint", self.lint, _.to-json())
    add("output", self.output, _.to-json())
    add("max_score", self.max-score, num-to-json)
    add("score", self.score, num-to-json)
    add("artifacts", self.artifacts, map-json(_.to-json()))
    add("annotations", self.annotations, map-json(_.to-json()))
    J.j-obj(sd.freeze())
  end
end

data PawtograderTest:
  | pawtograder-test(
    part :: Option<String>,
    output-format :: OutputFormat,
    output :: String,
    hidden-output :: Option<String>,
    hidden-output-format :: Option<OutputFormat>,
    name :: String,
    max-score :: Option<Number>,
    score :: Option<Number>,
    hide-until-released :: Option<Boolean>) with:
  method to-json(self) -> J.JSON block:
    sd = [SD.mutable-string-dict:]
    shadow add = add(sd, _, _, _)
    add("part", self.part, J.to-json)
    add("output_format", self.output-format, _.to-json())
    add("output", self.output, J.to-json)
    add("hidden_output", self.hidden-output, J.to-json)
    add("hidden_output_format", self.hidden-output-format, _.to-json())
    add("name", self.name, J.to-json)
    add("max_score", self.max-score, num-to-json)
    add("score", self.score, num-to-json)
    add("hide_until_released", self.hide-until-released, _.to-json())
    J.j-obj(sd.freeze())
  end
end

data PawtograderLint:
  | pawtograder-lint(
    output-format :: Option<OutputFormat>,
    output :: String,
    status :: PawtograderLintStatus) with:
  method to-json(self) -> J.JSON block:
    sd = [SD.mutable-string-dict:]
    shadow add = add(sd, _, _, _)
    add("output_format", self.output-format, _.to-json())
    add("output", self.output, J.to-json)
    add("status", self.status, _.to-json())
    J.j-obj(sd.freeze())
  end
end

data PawtograderLintStatus:
  | pass with:
  method to-json(self) -> J.JSON:
    J.j-str("pass")
  end
  | fail with:
  method to-json(self) -> J.JSON:
    J.j-str("fail")
  end
end

data PawtograderTopLevelOutput:
  | pawtograder-top-level-output(
      visible :: Option<PawtograderOutput>,
      hidden :: Option<PawtograderOutput>,
      after-due-date :: Option<PawtograderOutput>,
      after-published :: Option<PawtograderOutput>) with:
  method to-json(self) -> J.JSON block:
    sd = [SD.mutable-string-dict:]
    add(sd, "visible", self.visible, _.to-json())
    add(sd, "hidden", self.hidden, _.to-json())
    add(sd, "after_due_date", self.after-due-date, _.to-json())
    add(sd, "after_published", self.after-published, _.to-json())
    J.j-obj(sd.freeze())
  end
end

data PawtograderOutput:
  | pawtograder-output(output-format :: Option<OutputFormat>, output :: String) with:
  method to-json(self) -> J.JSON block:
    sd = [SD.mutable-string-dict:]
    add(sd, "output_format", self.output-format, _.to-json())
    add(sd, "output", self.output, J.to-json)
    J.j-obj(sd.freeze())
  end
end

data PawtograderArtifact:
  | pawtograder-artifact(
      name :: String,
      path :: String
      # TODO: what is data?
  ) with:
  method to-json(self) -> J.JSON block:
    sd = [SD.mutable-string-dict:]
    add(sd, "name", self.name, J.to-json)
    add(sd, "path", self.path, J.to-json)
    J.j-obj(sd.freeze())
  end
end

data PawtograderAnnotations:
  | feedback-comment(
      author :: PawtograderFeedbackAuthor,
      message :: String,
      points :: Option<Number>,
      rubric-check-id :: Option<Number>,
      released :: Boolean) with:
  method to-json(self) block:
    sd = self.common-sd(self)
    J.j-obj(sd.freeze())
  end
  | feedback-line-comment(
      author :: PawtograderFeedbackAuthor,
      message :: String,
      points :: Option<Number>,
      rubric-check-id :: Option<Number>,
      released :: Boolean,
      line :: Number,
      file-name :: String) with:
  method to-json(self) block:
    sd = self.common-sd(self)
    add(sd, "line", self.line, J.to-json)
    add(sd, "file_name", self.file-name, J.to-json)
    J.j-obj(sd.freeze())
  end
  | feedback-artifact-comment(
      author :: PawtograderFeedbackAuthor,
      message :: String,
      points :: Option<Number>,
      rubric-check-id :: Option<Number>,
      released :: Boolean,
      artifact-name :: String) with:
  method to-json(self) block:
    sd = self.common-sd(self)
    add(sd, "artifact_name", self.artifact-name, J.to-json)
    J.j-obj(sd.freeze())
  end
sharing:
  method common-sd(self) block:
    sd = [SD.mutable-string-dict:]
    add(sd, "author", self.author, _.to-json)
    add(sd, "message", self.message, J.to-json)
    add(sd, "points", self.points, num-to-json)
    add(sd, "rubric_check_id", self.rubric-check-id, num-to-json)
    add(sd, "released", self.released, J.to-json)
    sd
  end
end

data PawtograderFeedbackAuthor:
  | feedback-author(
      name :: String,
      avatar-url :: String,
      flair :: Option<String>,
      flair-color :: Option<String>) with:
  method to-json(self) block:
    sd = [SD.mutable-string-dict:]
    add(sd, "name", self.name, J.to-json)
    add(sd, "avatar_url", self.avatar-url, J.to-json)
    add(sd, "flair", self.flair, J.to-json)
    add(sd, "flair_color", self.flair-color, J.to-json)
    J.j-obj(sd.freeze())
  end
end

data OutputFormat:
  | text
  | markdown
  | ansi
sharing:
  method to-json(self):
    cases (OutputFormat) self:
      | text => J.j-str("text")
      | markdown => J.j-str("markdown")
      | ansi => J.j-str("ansi")
    end
  end
end


fun aggregate-output-to-pawtograder(output :: A.AggregateOutput) -> {OutputFormat; String}:
  cases (A.AggregateOutput) output:
    | output-text(content) => {text; content}
    | output-markdown(content) => {markdown; content}
    | output-ansi(content) => {ansi; content}
  end
end

fun aggregate-to-pawtograder-output(output :: A.AggregateOutput) -> PawtograderOutput:
  {output-format; output-text} = aggregate-output-to-pawtograder(output)
  pawtograder-output(some(output-format), output-text)
end

# n.b uses + rather than link to preserve order
# FIXME: do we really need to keep track of score and max-score?
fun prepare-for-pawtograder(output :: {List<{A.Id; A.AggregateResult;}>; String}) -> J.JSON block:
  {results; log} = output
  {tests; score; max-score} = for fold({acc-tests; acc-score; acc-max-score} from {[list:]; 0; 0},
                                       {id; res} from results):
    cases (A.AggregateResult) res block:
      | aggregate-skipped(name, so, io, max-score) =>
        {sof; sos} = aggregate-output-to-pawtograder(so)
        {iof; ios} = io.and-then(aggregate-output-to-pawtograder(_))
                       .and-then(lam({f; t}): {some(f); some(t)} end)
                       .or-else({none; none})

        test = pawtograder-test(
          none, # TODO: what is a part?
          sof,
          sos,
          ios,
          iof,
          name,
          some(max-score),
          some(0),
          none
        )
        {acc-tests + [list: test]; acc-score; acc-max-score + max-score}
      | aggregate-test(name, so, io, score, max-score) =>
        {sof; sos} = aggregate-output-to-pawtograder(so)
        {iof; ios} = io.and-then(aggregate-output-to-pawtograder(_))
                       .and-then(lam({f; t}): {some(f); some(t)} end)
                       .or-else({none; none})

        test = pawtograder-test(
          none, # TODO: what is a part?
          sof,
          sos,
          ios,
          iof,
          name,
          some(max-score),
          some(score),
          none
        )
        {acc-tests + [list: test]; acc-score + score; acc-max-score + max-score}
      | aggregate-artifact(_, _, _) => {acc-tests; acc-score; acc-max-score}
    end
  end

  artifacts = for fold(acc from [list:], {id; res} from results):
    cases (A.AggregateResult) res:
      | aggregate-skipped(_, _, _, _) => acc
      | aggregate-test(_, _, _, _, _) => acc
      | aggregate-artifact(name, path, _) => # TODO: what about artifact skip?
        # TODO: can we add id as metadata somewhere?
        artifact = pawtograder-artifact(name, path)
        acc + [list: artifact]
    end
  end

  student-output = some(aggregate-to-pawtograder-output(A.output-markdown(log))) # TODO: instructor log

  pawtograder-feedback(
    tests,
    pawtograder-lint(none, "", pass),
    pawtograder-top-level-output(student-output, none, none, none),
    some(max-score),
    some(score),
    artifacts,
    [list:]
  ).to-json()
end

