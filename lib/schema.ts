/*
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
*/

import { z } from "zod/v4";

export const Spec = z.object({
  solution_dir: z.string(),
  submission_dir: z.string(),
  get config() {
    return Config;
  },
});

export type Spec = z.infer<typeof Spec>;

export const Config = z.object({
  grader: z.literal("pyret"),
  /**
   * The default entry point to the student's program, relative to
   * {@link Spec.submission_dir}
   */
  default_entry: z.string().optional(),
  get graders() {
    return z.record(z.string(), Grader);
  },
});

export type Config = z.infer<typeof Config>;

const BaseGrader = z.object({
  deps: z.string().array().optional(),
  // TODO: reconsider this, maybe break into base scorer, guard, artifact
  // NOTE: do we want to enforce being positive?
  points: z.number().positive().optional(),
  /**
   * The path of the entry point to the student's program.
   *
   * Defaults to {@link Spec.config.default_entry}
   */
  entry: z.string().optional(),
});

const WellFormedGrader = BaseGrader.extend({
  type: z.literal("well-formed"),
});

const ExamplarGrader = BaseGrader.extend({
  type: z.union([z.literal("wheat"), z.literal("chaff")]),
  config: z.object({
    /** the path which contains the wheat/chaff implementation */
    path: z.string(),
    /** the name of the function to use */
    function: z.string(),
  }),
});

const FunctionalGrader = BaseGrader.extend({
  type: z.literal("functional"),
  config: z.object({
    /** the path which contain the check block */
    path: z.string(),
    /** the name of the check block to use in the provided path */
    check: z.string(),
  }),
});

const SelfTestGrader = BaseGrader.extend({
  type: z.literal("self-test"),
  config: z.object({
    /** the name of the function to use */
    function: z.string(),
  }),
});

export const Grader = z.union([
  WellFormedGrader,
  ExamplarGrader,
  FunctionalGrader,
  SelfTestGrader,
]);

export type Grader = z.infer<typeof Grader>;
