function FancyActionBar.HandleSpecial(id, change, updateTime, beginTime, endTime, unitTag, unitId)
  -- abilities that have multiple trigger ids.
  -- individual handling for each of them below.

  if FancyActionBar.specialEffects[id] then
    local specialEffect = ZO_DeepTableCopy(FancyActionBar.specialEffects[id]);
    for effectId, effect in pairs(FancyActionBar.effects) do
      if effect.id == specialEffect.id then
        local activeEffect = ZO_DeepTableCopy(effect);

        if (change == EFFECT_RESULT_GAINED or change == EFFECT_RESULT_UPDATED) then
          if (specialEffect.allowRecast ~= nil and specialEffect.allowRecast == false) and change == EFFECT_RESULT_UPDATED then return; end;
          if specialEffect.fixedTime then
            endTime = updateTime + specialEffect.fixedTime;
          else
            endTime = updateTime + (GetAbilityDuration(id) / 1000);
          end;
          if activeEffect.priority then
            -- Compare priorities and update accordingly
            if not specialEffect.priority or (specialEffect.priority <= activeEffect.priority) then
              local nextEffect = activeEffect;
              for i, x in pairs(specialEffect) do nextEffect[i] = x; end;
              nextEffect.beginTime = updateTime;
              nextEffect.endTime = endTime;
              nextEffect.stacks = nextEffect.priority or 0;
              FancyActionBar.stashedEffects[nextEffect.id] = {};
              FancyActionBar.stashedEffects[nextEffect.id][nextEffect.priority] = ZO_DeepTableCopy(nextEffect);
            else
              for i, x in pairs(specialEffect) do activeEffect[i] = x; end;
              activeEffect.beginTime = updateTime;
              activeEffect.endTime = endTime;
              activeEffect.stacks = activeEffect.priority;
              FancyActionBar.stacks[activeEffect.stackId] = activeEffect.stacks;
              FancyActionBar.stashedEffects[activeEffect.id] = {};
              FancyActionBar.stashedEffects[activeEffect.id][activeEffect.priority] = ZO_DeepTableCopy(activeEffect);
              FancyActionBar.effects[effectId] = ZO_DeepTableCopy(activeEffect);
              if FancyActionBar.activeCasts[activeEffect.id] then FancyActionBar.activeCasts[activeEffect.id].begin =
                updateTime; end;
            end;
          else
            if specialEffect.stacks then
              FancyActionBar.stacks[specialEffect.stackId] = specialEffect.stacks;
            end;
            for i, x in pairs(specialEffect) do activeEffect[i] = x; end;
            activeEffect.beginTime = updateTime;
            activeEffect.endTime = endTime;
            FancyActionBar.effects[effectId] = ZO_DeepTableCopy(activeEffect);
            if FancyActionBar.activeCasts[activeEffect.id] then FancyActionBar.activeCasts[activeEffect.id].begin =
              updateTime; end;
          end;
        elseif change == EFFECT_RESULT_FADED then
          -- Ignore the Ability Fading in the Same GCD as it was cast (indicates a recast)
          if activeEffect.beginTime and (activeEffect.beginTime > updateTime - 0.5) then return; end;
          -- Ignore the ability fading because it either already proced it's next effect
          if activeEffect.priority then
            if activeEffect.priority > 0 then
              local stashedEffects, nextEffect;
              stashedEffects = FancyActionBar.stashedEffects[activeEffect.id];
              nextEffect = stashedEffects[activeEffect.priority - 1] and
              ZO_DeepTableCopy(stashedEffects[activeEffect.priority - 1]);
              if nextEffect then
                for i, x in pairs(nextEffect) do activeEffect[i] = x; end;
                activeEffect.stacks = activeEffect.priority;
                FancyActionBar.stacks[activeEffect.stackId] = activeEffect.stacks;
                if FancyActionBar.activeCasts[activeEffect.id] then FancyActionBar.activeCasts[activeEffect.id].begin =
                  activeEffect.beginTime; end;
              end;
            else
              FancyActionBar.stashedEffects[activeEffect.id] = nil;
            end;
          elseif FancyActionBar.specialEffectProcs[id] then
            if (activeEffect.hasProced and specialEffect.hasProced) and (activeEffect.hasProced > specialEffect.hasProced) then return; end;
            local procUpdates = FancyActionBar.specialEffectProcs[id];
            local procValues = procUpdates[activeEffect.procs];
            for i, x in pairs(procValues) do activeEffect[i] = x; end;
          end;
          if activeEffect.stacks then
            FancyActionBar.stacks[activeEffect.stackId] = activeEffect.stacks;
          end;
          FancyActionBar.effects[effectId] = ZO_DeepTableCopy(activeEffect);
        end;
      end;
      FancyActionBar.UpdateEffect(FancyActionBar.effects[effectId]);
      if update then
        FancyActionBar.HandleStackUpdate(FancyActionBar.effects[effectId].id);
      end;
    end;
  else
    local effect;        -- the ability we are updating
    local update = true; -- update the stacks display for the ability. not sure why I called it this.
    -- The old system of special effectIds
    if (change == EFFECT_RESULT_GAINED or change == EFFECT_RESULT_UPDATED) then
      if (id == 40465) then -- scalding rune placed
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[id];
        update = false;
      elseif (id == 46331) then -- crystal weapon
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[id];
        FancyActionBar.stacks[effect.id] = 2;
        update = true;
      elseif FancyActionBar.meteor[id] then
        FancyActionBar.effects[FancyActionBar.meteor[id]].stackId = FancyActionBar.meteor[id];
        effect = FancyActionBar.effects[FancyActionBar.meteor[id]];
      elseif FancyActionBar.frozen[id] then -- (id == 86179) then -- frozen device
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[id];
        if not FancyActionBar.stacks[id] then FancyActionBar.stacks[id] = 0; end;
        fdNum = fdNum + 1;
        fdStacks[fdNum] = beginTime;
        FancyActionBar.stacks[id] = fdNum;
      elseif (id == 37475) then -- manifestation of terror cast
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[id];
        FancyActionBar.stacks[effect.id] = 1;
        endTime = endTime - 0;
      elseif (id == 76634) then -- manifestation of terror trigger
        FancyActionBar.effects[37475].stackId = 37475;
        effect = FancyActionBar.effects[37475];
        FancyActionBar.stacks[37475] = FancyActionBar.stacks[37475] - 1;
        if FancyActionBar.stacks[37475] <= 0 then endTime = updateTime; end;
      elseif id == FancyActionBar.sCorch.id1 then
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[id];
        if not FancyActionBar.stacks[id] then FancyActionBar.stacks[id] = 0; end;
        FancyActionBar.stacks[id] = 2;
        endTime = updateTime + 9;
      elseif id == FancyActionBar.subAssault.id1 then
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[id];
        if not FancyActionBar.stacks[id] then FancyActionBar.stacks[id] = 0; end;
        FancyActionBar.stacks[id] = 2;
        endTime = updateTime + 6;
      else
        if FancyActionBar.effects[id] then
          FancyActionBar.effects[id].stackId = id;
          effect = FancyActionBar.effects[id];
        end;
      end;
      if effect then
        -- effect.faded    = false
        effect.endTime = endTime;
        if FancyActionBar.activeCasts[effect.id] then FancyActionBar.activeCasts[effect.id].begin = updateTime; end;
      end;
    elseif (change == EFFECT_RESULT_FADED) then
      if FancyActionBar.meteor[id] then
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[FancyActionBar.meteor[id]];
        effect.endTime = endTime;
      elseif (id == 46331) then -- crystal weapon
        -- if unitTag == 'reticleover' then return end
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[id];
        FancyActionBar.stacks[effect.id] = 0;
        effect.endTime = endTime;
        update = true;
      elseif id == FancyActionBar.sCorch.id1 then
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[id];
        if FancyActionBar.stacks[id] == 2 then FancyActionBar.stacks[id] = 1; end;
      elseif id == FancyActionBar.sCorch.id2 then
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[FancyActionBar.sCorch.id1];
        if effect.endTime <= updateTime
        then
          FancyActionBar.stacks[FancyActionBar.sCorch.id1] = 0;
        else
          update = false;
        end;
      elseif id == FancyActionBar.subAssault.id1 then
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[id];
        if FancyActionBar.stacks[id] == 2 then FancyActionBar.stacks[id] = 1; end;
      elseif id == FancyActionBar.subAssault.id2 then
        FancyActionBar.effects[FancyActionBar.subAssault.id1].stackId = id;
        effect = FancyActionBar.effects[FancyActionBar.subAssault.id1];
        if effect.endTime <= updateTime
        then
          FancyActionBar.stacks[FancyActionBar.subAssault.id1] = 0;
        else
          update = false;
        end;
      elseif FancyActionBar.frozen[id] then -- (id == 86179) then -- frozen device
        FancyActionBar.effects[id].stackId = id;
        if FancyActionBar.effects[id].endTime == 0 then return; end;
        if not FancyActionBar.stacks[id] then return; end;
        local faded = 0;
        local fadeTime = 0;
        for i = 1, #fdStacks do
          if fdStacks[i] == beginTime then
            faded = i;
            fdStacks = nil;
          else
            if (fdStacks[i] > fadeTime) then fadeTime = fdStacks[i]; end;
          end;
          if (faded > 0 and i > faded) then fdStacks[i - 1] = fdStacks[i]; end;
        end;

        effect = FancyActionBar.effects[id];
        fdNum = fdNum - 1;
        if fdNum >= 1 then
          if fadeTime + 15.5 > updateTime then
            effect.endTime = fadeTime + 15.5;
            FancyActionBar.stacks[id] = fdNum;
          else
            FancyActionBar.stacks[id] = 0;
            effect.endTime = endTime;
          end;
        else
          FancyActionBar.stacks[id] = 0;
          effect.endTime = endTime;
        end;
      elseif id == 37475 then -- manifestation of terror
        FancyActionBar.effects[id].stackId = id;
        effect = FancyActionBar.effects[id];
        if effect.endTime - updateTime > 1 and FancyActionBar.stacks[id] > 0 then
          return;
        elseif effect.endTime <= updateTime + 1 then
          FancyActionBar.stacks[id] = 0;
        end;
      end;
    end;
    if effect then
      FancyActionBar.UpdateEffect(effect);
      if update then
        FancyActionBar.HandleStackUpdate(effect.id);
      end;
    else
      return;
    end;
  end;
end;
