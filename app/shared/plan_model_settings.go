package shared

var SettingDescriptions = map[string]string{
	"max-convo-tokens":       "max conversation 🪙 before summarization",
	"max-tokens":             "overall 🪙 limit",
	"reserved-output-tokens": "🪙 reserved for model output",
}

var ModelOverridePropsDasherized = []string{"max-convo-tokens", "max-tokens", "reserved-output-tokens"}

func (ps PlanSettings) GetPlannerMaxTokens() int {
	if ps.ModelOverrides.MaxTokens == nil {
		if ps.ModelPack == nil {
			defaultPlanner := DefaultModelPack.Planner
			return defaultPlanner.GetFinalLargeContextFallback().BaseModelConfig.MaxTokens
		} else {
			planner := ps.ModelPack.Planner
			return planner.GetFinalLargeContextFallback().BaseModelConfig.MaxTokens
		}
	} else {
		return *ps.ModelOverrides.MaxTokens
	}
}

func (ps PlanSettings) GetPlannerMaxReservedOutputTokens() int {
	if ps.ModelOverrides.MaxTokens == nil {
		if ps.ModelPack == nil {
			defaultPlanner := DefaultModelPack.Planner
			return defaultPlanner.GetFinalLargeContextFallback().GetReservedOutputTokens()
		} else {
			planner := ps.ModelPack.Planner
			return planner.GetFinalLargeContextFallback().GetReservedOutputTokens()
		}
	} else {
		return *ps.ModelOverrides.MaxTokens
	}
}

func (ps PlanSettings) GetArchitectMaxTokens() int {
	if ps.ModelOverrides.MaxTokens == nil {
		if ps.ModelPack == nil {
			defaultLoader := DefaultModelPack.GetArchitect()
			return defaultLoader.GetFinalLargeContextFallback().BaseModelConfig.MaxTokens
		} else {
			loader := ps.ModelPack.GetArchitect()
			return loader.GetFinalLargeContextFallback().BaseModelConfig.MaxTokens
		}
	} else {
		return *ps.ModelOverrides.MaxTokens
	}
}

func (ps PlanSettings) GetArchitectMaxReservedOutputTokens() int {
	if ps.ModelOverrides.MaxTokens == nil {
		if ps.ModelPack == nil {
			defaultLoader := DefaultModelPack.GetArchitect()
			return defaultLoader.GetFinalLargeContextFallback().GetReservedOutputTokens()
		} else {
			loader := ps.ModelPack.GetArchitect()
			return loader.GetFinalLargeContextFallback().GetReservedOutputTokens()
		}
	} else {
		return *ps.ModelOverrides.MaxTokens
	}
}

func (ps PlanSettings) GetWholeFileBuilderMaxTokens() int {
	if ps.ModelOverrides.MaxTokens == nil {
		if ps.ModelPack == nil {
			defaultBuilder := DefaultModelPack.WholeFileBuilder
			return defaultBuilder.GetFinalLargeContextFallback().BaseModelConfig.MaxTokens
		} else {
			builder := ps.ModelPack.WholeFileBuilder
			return builder.GetFinalLargeContextFallback().BaseModelConfig.MaxTokens
		}
	} else {
		return *ps.ModelOverrides.MaxTokens
	}
}

func (ps PlanSettings) GetWholeFileBuilderMaxReservedOutputTokens() int {
	if ps.ModelOverrides.MaxTokens == nil {
		if ps.ModelPack == nil {
			defaultBuilder := DefaultModelPack.WholeFileBuilder
			return defaultBuilder.GetFinalLargeOutputFallback().GetReservedOutputTokens()
		} else {
			builder := ps.ModelPack.WholeFileBuilder
			return builder.GetFinalLargeOutputFallback().GetReservedOutputTokens()
		}
	} else {
		return *ps.ModelOverrides.MaxTokens
	}
}

func (ps PlanSettings) GetPlannerMaxConvoTokens() int {
	if ps.ModelOverrides.MaxConvoTokens == nil {
		if ps.ModelPack == nil {
			defaultPlanner := DefaultModelPack.Planner
			return defaultPlanner.GetFinalLargeContextFallback().MaxConvoTokens
		} else {
			planner := ps.ModelPack.Planner
			return planner.GetFinalLargeContextFallback().MaxConvoTokens
		}
	} else {
		return *ps.ModelOverrides.MaxConvoTokens
	}
}

func (ps PlanSettings) GetPlannerEffectiveMaxTokens() int {
	maxPlannerTokens := ps.GetPlannerMaxTokens()
	maxReservedOutputTokens := ps.GetPlannerMaxReservedOutputTokens()

	return maxPlannerTokens - maxReservedOutputTokens
}

func (ps PlanSettings) GetArchitectEffectiveMaxTokens() int {
	maxArchitectTokens := ps.GetArchitectMaxTokens()
	maxReservedOutputTokens := ps.GetArchitectMaxReservedOutputTokens()

	return maxArchitectTokens - maxReservedOutputTokens
}

func (ps PlanSettings) GetWholeFileBuilderEffectiveMaxTokens() int {
	maxWholeFileBuilderTokens := ps.GetWholeFileBuilderMaxTokens()
	maxReservedOutputTokens := ps.GetWholeFileBuilderMaxReservedOutputTokens()

	return maxWholeFileBuilderTokens - maxReservedOutputTokens
}

func (ps PlanSettings) GetRequiredEnvVars() map[string]bool {
	envVars := map[string]bool{}

	ms := ps.ModelPack
	if ms == nil {
		ms = DefaultModelPack
	}
	if ms == nil {
		envVars["OPENAI_API_KEY"] = true
		return envVars
	}

	// Required components - get through GetFinalLargeContextFallback first
	if config := ms.Planner.GetFinalLargeContextFallback(); config.BaseModelConfig.ApiKeyEnvVar != "" {
		envVars[config.BaseModelConfig.ApiKeyEnvVar] = true
	} else {
		envVars["OPENAI_API_KEY"] = true
	}

	if config := ms.Builder.GetFinalLargeContextFallback(); config.BaseModelConfig.ApiKeyEnvVar != "" {
		envVars[config.BaseModelConfig.ApiKeyEnvVar] = true
	} else {
		envVars["OPENAI_API_KEY"] = true
	}

	if config := ms.PlanSummary.GetFinalLargeContextFallback(); config.BaseModelConfig.ApiKeyEnvVar != "" {
		envVars[config.BaseModelConfig.ApiKeyEnvVar] = true
	} else {
		envVars["OPENAI_API_KEY"] = true
	}

	if config := ms.Namer.GetFinalLargeContextFallback(); config.BaseModelConfig.ApiKeyEnvVar != "" {
		envVars[config.BaseModelConfig.ApiKeyEnvVar] = true
	} else {
		envVars["OPENAI_API_KEY"] = true
	}

	if config := ms.CommitMsg.GetFinalLargeContextFallback(); config.BaseModelConfig.ApiKeyEnvVar != "" {
		envVars[config.BaseModelConfig.ApiKeyEnvVar] = true
	} else {
		envVars["OPENAI_API_KEY"] = true
	}

	if config := ms.ExecStatus.GetFinalLargeContextFallback(); config.BaseModelConfig.ApiKeyEnvVar != "" {
		envVars[config.BaseModelConfig.ApiKeyEnvVar] = true
	} else {
		envVars["OPENAI_API_KEY"] = true
	}

	// Optional components - check pointer first
	if ms.WholeFileBuilder != nil {
		if config := ms.WholeFileBuilder.GetFinalLargeContextFallback(); config.BaseModelConfig.ApiKeyEnvVar != "" {
			envVars[config.BaseModelConfig.ApiKeyEnvVar] = true
		} else {
			envVars["OPENAI_API_KEY"] = true
		}
	} else {
		envVars["OPENAI_API_KEY"] = true
	}

	if ms.Architect != nil {
		if config := ms.Architect.GetFinalLargeContextFallback(); config.BaseModelConfig.ApiKeyEnvVar != "" {
			envVars[config.BaseModelConfig.ApiKeyEnvVar] = true
		} else {
			envVars["OPENAI_API_KEY"] = true
		}
	} else {
		envVars["OPENAI_API_KEY"] = true
	}

	if ms.Coder != nil {
		if config := ms.Coder.GetFinalLargeContextFallback(); config.BaseModelConfig.ApiKeyEnvVar != "" {
			envVars[config.BaseModelConfig.ApiKeyEnvVar] = true
		} else {
			envVars["OPENAI_API_KEY"] = true
		}
	} else {
		envVars["OPENAI_API_KEY"] = true
	}

	return envVars
}
